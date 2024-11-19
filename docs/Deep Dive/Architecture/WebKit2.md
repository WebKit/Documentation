# WebKit2

WebKit’s Multi-Process Architecture

## Overview

In order to safeguard the rest of the system and allow the application to remain responsive
even if the user had loaded web page that infinite loops or otherwise hangs,
the modern incarnation of WebKit uses multi-process architecture.
Web pages are loaded in its own *WebContent* process.
Multiple WebContent processes can share a browsing session, which lives in a shared network process.
In addition to handling all network accesses,
this process is also responsible for managing the disk cache and Web APIs that allow websites
to store structured data such as [Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API)
and [IndexedDB API](https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API):
![Diagram of WebKit2's multi-process architecture](/assets/Webkit2ProcessArchitecture.png)
Because a WebContent process can Just-in-Time compile arbitrary JavaScript code loaded from the internet,
meaning that it can write to memory that gets executed, this process is tightly sandboxed.
It does not have access to any file system unless the user grants an access,
and it does not have direct access to the underlying operating system’s [clipboard](https://en.wikipedia.org/wiki/Clipboard_(computing)),
microphone, or video camera even though there are Web APIs that grant access to those features.
Instead, UI process brokers such requests.

## How is IPC Setup

In WebKit, Inter-Process Communication (IPC) enables communication between different processes. The IPC setup in WebKit involves several key components:

### Message Definitions

Messages are defined in `*.messages.in` files (e.g., `WebPage.messages.in`). These files specify the structure and types of messages exchanged between processes. Each `*.messages.in` file must map to a header file with the same name (e.g., `WebPage.messages.in` maps to `WebPage.h`). These `*.messages.in` files are processed at build time to generate source code for receiving IPC messages. They support both synchronous and asynchronous messages.

### Message Handlers

Each process has message handlers that process incoming messages and perform the necessary actions. The message definitions in the `*.messages.in` file need to have corresponding implementations in the related class (e.g., `WebPage` implements handlers for the corresponding messages defined in `WebPage.messages.in`). The processing of the `*.messages.in` files during build time generates source code that maps a message definition to its corresponding handler implementation, which will automatically call it for you when that message is received. The message handlers must adhere to the correct function signatures specified in the `*.messages.in` files, otherwise you will get a build error.

### IPC::MessageSender and IPC::MessageReceiver

Classes that send or receive IPC messages typically inherit from `IPC::MessageSender` and `IPC::MessageReceiver`. These base classes automatically handle the serialization and deserialization of messages, as well as the setup of message dispatching.

For a deeper dive, you can found WebKit's IPC code in the `Source/WebKit/Platform/IPC` directory. This directory contains the classes and utilities needed to manage IPC, including message sending and receiving, connection management, and the serialization and deserialization of messages.

## How to Add or Modify an IPC Message

Adding or modifying an IPC message in WebKit involves several steps to ensure proper communication between classes in different processes. Here is a step-by-step guide:

### 1. Define the Message

Locate the appropriate `*.messages.in` file (e.g., `WebPage.messages.in`). If a new message file is needed, it should be placed in the same directory as the class you are implementing it for and it should also be added to the directory's `Sources.txt` file, as mentioned [here](../Build/AddingNewFile.html).
Now, define the new message in this file. For example, let's say we want to send a message called `LoadURL` from the UI process' `WebPageProxy` class to the WebContent process' `WebPage` class. In `WebPage.messages.in`, you would add an entry like:

```
LoadURL(String url)
```

### 2. Implement the Message Handler

In the class that will receive the message (e.g., `WebPage`), implement the handler method. This method will be called when the message is received. For example:

```
void WebPage::loadURL(const String& url) {
    // Implementation code to load the URL
}
```

### 3. Send the Message

To send the message from another process, use the `send` method of the `IPC::MessageSender` class. For example, to send the `LoadURL` message from the UI process' `WebPageProxy` class to the WebContent's `WebPage` class:

```
send(Messages::WebPage::LoadURL(url));
```

Note, `WebPageProxy` inherits from `IPC::MessageSender`, which is what makes this possible.

## Replying to Messages

In addition to sending messages, WebKit's IPC mechanism supports replying to messages, which can be done synchronously or asynchronously.

### 1. Define the Message Reply

In the definition of the message in the `*.messages.in` file, specify that it expects a reply. For example, in `WebPage.messages.in`:

```
GetTitle() -> (String title)
```

By default, the reply is handled asynchronously. In order to make it synchronous, add `Synchronous` after the message definition, for example:

```
GetTitle() -> (String title) Synchronous
```

### 2. Implement the Message Handler with Reply

Implement the handler method in the receiving class that will process the message and send a reply. For example, in the WebContent process' `WebPage.h`:

```
void WebPage::getTitle(CompletionHandler<void(String)>&& completionHandler) {
    completionHandler(m_title);
}
```

### 3. Send the Asynchronous Message and Handle Reply

To send the asynchronous message and handle the reply, use the `sendWithAsyncReply` method of the `IPC::MessageSender` class. For example, in the UI process' `WebPageProxy.cpp`:

```
sendWithAsyncReply(Messages::WebPage::GetTitle(), [this, weakThis = WeakPtr { *this }](String title) {
    // do something with title...
});
```
