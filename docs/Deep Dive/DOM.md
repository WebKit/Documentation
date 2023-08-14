# DOM

A deep dive into the Document Object Model.

## Introduction

[Document Object Model](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model)
(often abbreviated as DOM) is the tree data structured resulted from parsing HTML.
It consists of one or more instances of subclasses of [Node](https://developer.mozilla.org/en-US/docs/Web/API/Node)
and represents the document tree structure. Parsing a simple HTML like this:

```cpp
<!DOCTYPE html>
<html>
<body>hi</body>
</html>
```

Will generate the following six distinct DOM nodes:

* [Document](https://developer.mozilla.org/en-US/docs/Web/API/Document)
    * [DocumentType](https://developer.mozilla.org/en-US/docs/Web/API/DocumentType)
    * [HTMLHtmlElement](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/html)
        * [HTMLHeadElement](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/head)
        * [HTMLBodyElement](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/body)
            * [Text](https://developer.mozilla.org/en-US/docs/Web/API/Text) with the value of “hi”

Note that HTMLHeadElement (i.e. `<head>`) is created implicitly by WebKit
per the way [HTML parser](https://html.spec.whatwg.org/multipage/parsing.html#parsing) is specified.

Broadly speaking, DOM node divides into the following categories:

* [Container nodes](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/ContainerNode.h) such as [Document](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h), [Element](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Element.h), and [DocumentFragment](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/DocumentFragment.h).
* Leaf nodes such as [DocumentType](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/DocumentType.h), [Text](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Text.h), and [Attr](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Attr.h).

[Document](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/dom/Document.h) node,
as the name suggests a single HTML, SVG, MathML, or other XML document,
and is the [owner](https://github.com/WebKit/WebKit/blob/ea1a56ee11a26f292f3d2baed2a3aea95fea40f1/Source/WebCore/dom/Node.h#L359) of every node in the document.
It is the very first node in any document that gets created and the very last node to be destroyed.

Note that a single web [page](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/Page.h) may consist of multiple documents
since [iframe](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)
and [object](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/object) elements may contain
a child [frame](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/Frame.h),
and form a [frame tree](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/page/FrameTree.h).
Because JavaScript can [open a new window](https://developer.mozilla.org/en-US/docs/Web/API/Window/open)
under user gestures and have [access back to its opener](https://developer.mozilla.org/en-US/docs/Web/API/Window/opener),
multiple web pages across multiple tabs might be able to communicate with one another via JavaScript API
such as [postMessage](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage).


# Inserting and Removing DOM Nodes

Document Object Model (DOM) manipulation is a crucial aspect of web development, allowing you to dynamically modify the structure and content of your web page. This documentation will guide you through the process of inserting and removing DOM nodes using JavaScript.



## Inserting DOM Nodes

### Creating New Nodes

To insert a new DOM element, first create the element using `document.createElement` method. This method will create a new HTML element with 
a specific tag name. Once the element is created, you can further modify its attributes and content.

<h4>Example: </h4>

```
const newElement = document.createElement('div');

```
### Specifying Node Properties

Once the new node is created,you can set properties and attributes
```
newParagraph.textContent = 'This is a new paragraph.';
newParagraph.setAttribute('class', 'highlight');

```
### Locating the Parent Node
Next, you'll need to locate the parent node where the new node will be inserted:

```
const parent = document.getElementById('parent');
```

### Inserting New Node

The `appendChild` method is used to add a child node to parent node. It appends the specified child node as the last child 
of the parent node.

<h4>Example: </h4>

```
parentElement.appendChild(newElement);

```

### insertBefore

The `insertBefore` method allows you to insert a new node before an existing child node within a parent node.

<h4>Example: </h4>

```
const siblingElement = document.getElementById('sibling');
parentElement.insertBefore(newElement, siblingElement);

```

### Updating Layout and Rendering 

After insertion, the Webkit engine recalculates the layout and rendes the updated page.This involves reflowing the affected parts of the page to accommondate the new node.

## Removal of Nodes

### Locating the Node to Remove

To remove an existing node from the DOM, locate the node using methods like `document.querySelector()`:

```
const nodeToRemove = document.querySelector('.remove-me');
```

### Removing the Node

Remove the node using `.removeChild()` on its parent node:

```
const parent = nodeToRemove.parentNode;
parent.removeChild(nodeToRemove);
```

### Updating Layout and Rendering 

Similar to insertion, removing a node triggers layout recalculations and updates in the rendering engine.

### Performance Considerations

Efficient DOM manipulation is crucial for optimal user experience.Consider the following steps:

### Batch Operations

Group multiple insertions/removals together to minimize layout recalculations:

```
const fragment = document.createDocumentFragment();
//this will append nodes to the fragment
parent.appendChild(fragment); //Single layout recalculation
```

### Using DocumentFragment

`DocumentFragment` helps with batch operations by allowing you to create node off-DOM before insertion:

```
const fragment = document.createDocumentFragment();
// Append nodes to the fragment
parent.appendChild(fragment); // Single layout recalculation
```

### CSS Classes and Styling

Apply CSS classes for styling changes instead of modifying properties individually:

```
newParagraph.classList.add('highlight');
```

### Debouncing and Throttling 

For performance sensitive DOM updates triggered by events, use techniques like debouncing or throttling to control frequency:

```
function debounce(callback, delay) {
  let timeoutId;
  return function () {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(callback, delay);
  };
}
```

### References 
 * [WebKit Official Documentation](https://webkit.org/t)
 *[MDN Web Docs - DOM Manipulation](https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model)

 