from   lxml import etree
import consts
import copy
import helpers
import re
import tables

def filterUnannotated(nodes):
    cond = lambda e: helpers.isAnnotated(e)
    return filter(cond, nodes)

def isAnnotated(e):
    try:
        return e.attrib[consts.RESERVED_XML_TYPE] != ''
    except:
        pass
    return False

def deleteAttribFromTree(t, attrib):
    if t == None:
        return
    if hasattr(t, 'attrib') and attrib in t.attrib:
        del t.attrib[attrib]

    for e in t:
        deleteAttribFromTree(e, attrib)

def annotateWithTypes(tree):
    for t in tables.TYPES:
        parentType = t[0]
        pattern    = t[1]
        matchType  = t[2]

        if   pattern == '/':
            exp = '/*'
            matches = tree.xpath(exp)
        elif pattern == '/[^a-z]/':
            exp = '//*[@%s="%s"]/*' % (consts.RESERVED_XML_TYPE, parentType)
            matches = tree.xpath(exp)
            matches = getNonLower(matches)
        else:
            exp  = '//*[@%s="%s"]/%s'
            exp %= (consts.RESERVED_XML_TYPE, parentType, pattern)
            matches = tree.xpath(exp)
        flagAll(matches, consts.RESERVED_XML_TYPE, matchType)


def replaceElement(element, replacements, tag=''):
    replacements = re.sub('>\s+<', '><', replacements)
    replacements = replacements.replace('__REPLACE__', tag)
    replacements = '<root>%s</root>' % replacements
    replacements = etree.fromstring(replacements)

    originalSourceline = element.sourceline
    helpers.setSourceline(replacements, originalSourceline)

    # Insert each element in `replacements` at the location of `element`. The
    # phrasing is a bit opaque here because lxml *moves* nodes from
    # `replacements` instead of copying them, when `insert(index, r)` is called.
    index = element.getparent().index(element)
    while len(replacements):
        r = replacements[-1]
        element.getparent().insert(index, r)

    element.getparent().remove(element)

def isFlagged(element, flag, checkAncestors=True, attribName='f'):
    if element is None:
        return False
    if attribName not in element.attrib:
        return False
    flags = element.attrib[attribName].split()
    if flag in flags:
        return True

    if checkAncestors:
        return isFlagged(element.getparent(), flag, checkAncestors, attribName)

def setSourceline(t, sourceline):
    if t == None:
        return

    t.sourceline = sourceline
    for e in t:
        setSourceline(e, sourceline)

def getNonLower(t):
    nodes = [i for i in t if re.match('[^a-z]', i.tag)] # TODO: Might be failing due to comments
    return nodes

def normaliseAttributes(node):
    for key, val in node.attrib.iteritems():
        val = val.split()
        val.sort()
        node.attrib[key] = ' '.join(val)

    for n in node:
        normaliseAttributes(n)

def wMsg(notice, nodes, expected=[]):
    notice = 'WARNING: ' + notice
    printNotice(notice, nodes, expected)

def eMsg(notice, nodes, expected=[]):
    notice = 'ERROR:   ' + notice
    printNotice(notice, nodes, expected)

def printNotice(notice, nodes, expected=[]):
    notice = notice + '.  '

    if   len(expected) == 0:
        expected = ''
    elif len(expected) == 1:
        expected = 'Allowed item is %s.  ' % expected[0]
    else:
        expected = 'Allowed items are:\n  - ' + '\n  - '.join(expected) + '\n'

    if len(nodes) == 0:
        location = ''
    if len(nodes) == 1:
        location = 'Occurs at line ' + str(nodes[0].sourceline) + '.  '
    if len(nodes) >= 2:
        location = 'Occurs at:'
        for node in nodes:
            location += '\n  - Line ' + str(node.sourceline)

    print notice + expected + location
    print


def bye(countWar, countErr, early=True):
    print 'Validation completed with %i error(s) and %i warning(s).' \
            % (countErr, countWar)
    exit()

def flagAll(nodes, attrib, value):
    for n in nodes:
        n.attrib[attrib] = value

def getExpectedTypes(table, node, reserved=False):
    attribType = '__RESERVED_XML_TYPE__'

    parent = node.getparent()

    # Get expected type(s)
    expected = []
    for row in table:
        parentType = row[0]
        pattern    = row[1]
        matchType  = row[2]

        if parent.attrib[attribType] != parentType:
            continue

        if   reserved == True:
            regex = '[^a-z]'
        elif reserved == False:
            regex = '^[a-z]+$'
        elif reserved == None:
            regex = '.*'
        else:
            continue

        if re.match(regex, matchType):
            expected.append(matchType)

    return expected

def getAttributes(table, xmlType, rowIndex=1):
    for row in table:
        rowXmlType = row[0]
        rowAttribs = row[rowIndex]

        if type(rowAttribs) is not list:
            if not rowAttribs:
                rowAttribs = []
            else:
                rowAttribs = [rowAttribs]

        for i in range(len(rowAttribs)):
            if   rowAttribs[i] == '$link-all':
                rowAttribs[i] = 'a valid link to a tab or tab group'
            elif rowAttribs[i] == '$link-tabgroup':
                rowAttribs[i] = 'a valid link to a tab group'
            elif rowAttribs[i] == '$link-tab':
                rowAttribs[i] = 'a valid link to a tab'

        if rowXmlType == xmlType:
            return rowAttribs

def isValidLink(root, link, linkType):
    if not link:
        return False

    if   linkType == 'tab':
        result  = True
        try:
            result &= bool(root.xpath('/module/' + link))
        except:
            result &= False
        result &= '/'     in link
        result &= '/' != link[ 0]
        result &= '/' != link[-1]
        return result
    elif linkType == 'tabgroup':
        result  = True
        try:
            result &= bool(root.xpath('/module/' + link))
        except:
            result &= False
        result &= '/' not in link
        return result
    elif linkType == 'all':
        result  = False
        result |= isValidLink(root, link, 'tab'     )
        result |= isValidLink(root, link, 'tabgroup')
        return result
    else:
        return False

def disallowedAttribVals(tree, m, ATTRIB_VALS):
    disallowed = []
    for attrib, oneOf, manyOf in ATTRIB_VALS:
        if attrib not in m.attrib: # Set intersection of attrib and m.attrib
            continue

        if oneOf:
            if '$link' in oneOf:
                link = m.attrib[attrib]
                linkType = oneOf[6:] # 'all', 'tab', or 'tabgroup'
                if not isValidLink(tree, link, linkType):
                    disallowed.append((attrib, m.attrib[attrib], m))
            else:
                if m.attrib[attrib] not in oneOf:
                    disallowed.append((attrib, m.attrib[attrib], m))
        if manyOf:
            for flag in m.attrib[attrib].split():
                if flag not in manyOf:
                    disallowed.append((attrib, flag,             m))
    return disallowed

def satisfiesTypeCardinalityConstraint(parent, constraint, children='direct'):
    min, type, max = constraint
    if type == None:
        return True

    if children == 'direct':
        children = ''
    else:
        children = './/'
    matches = parent.xpath(
            '%s*[@%s="%s"]' %
            (children, consts.RESERVED_XML_TYPE, type)
    )

    if min != None and len(matches) < min: return False
    if max != None and len(matches) > max: return False
    return True

# English is dumb
def childWithGrammaticalNumber(number):
    if number == 1:
        return 'child'
    return 'children'
def descendantWithGrammaticalNumber(number):
    d = 'descendant'; s = 's'
    if number == 1:
        return d
    return  d + s
def descChildNounPhrase(child, number):
    if  childDirectness == 'direct':
        childNum = childWithGrammaticalNumber (number)
        return 'direct %s' % childNum
    else:
        return descendantWithGrammaticalNumber(number)

def guessType(node):
    # Don't guess the type if it's already there
    try:
        return node.attrib['t']
    except:
        pass

    # Okay, fine. Go ahead and give 'er a guess.
    isUser = 'f' in node.attrib and 'user' in node.attrib['f'].split()
    if isUser:
        return 'list'
    if node.xpath('opts') and     node.xpath('.//opt[@p]'):
        return 'picture'
    if node.xpath('opts') and not node.xpath('.//opt[@p]'):
        return 'dropdown'
    return 'input'

def checkTagCardinalityConstraints(tree, nodeTypeParent, nodeTypeChild, schemaType):
    assert schemaType in ['UI', 'data']

    countErr = 0; ok = True

    elements = tree.xpath(
            '//*[@%s="%s"]' %
            (consts.RESERVED_XML_TYPE, nodeTypeChild)
    )

    for original in elements:
        duplicatesAndSelf = original.xpath(
                './ancestor::*[@%s="%s"]//%s[@%s="%s" and not(@%s="true")]' %
                (
                    consts.RESERVED_XML_TYPE, nodeTypeParent, original.tag,
                    consts.RESERVED_XML_TYPE, nodeTypeChild,
                    consts.RESERVED_IGNORE
                )
        )
        if schemaType == 'UI'  : cond = lambda n: not isFlagged(n, 'noui')
        if schemaType == 'data': cond = lambda n: not isFlagged(n, 'nodata')
        duplicatesAndSelf = filter(cond, duplicatesAndSelf)

        for original in duplicatesAndSelf: # Make sure not to re-check duplicate
            original.attrib[consts.RESERVED_IGNORE] = "true"
        if len(duplicatesAndSelf) <= 1:
            continue # If this runs, no duplicates were found

        capitalisedType = nodeTypeChild[0].upper() + nodeTypeChild[1:]
        pluralisedType  = nodeTypeChild + 's'
        msg  = '%s `%s` is illegally duplicated or results in illegal duplicate'
        msg += ' %s in its parent %s when the %s schema is generated'
        msg  = msg % \
                (
                        capitalisedType,
                        original.tag,
                        pluralisedType,
                        nodeTypeParent,
                        schemaType
                )
        eMsg(
                msg,
                duplicatesAndSelf
        )
        countErr += 1; ok &= False

    deleteAttribFromTree(elements, consts.RESERVED_IGNORE)
    return (countErr, ok)