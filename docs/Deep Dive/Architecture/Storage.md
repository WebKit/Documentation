# Storage

## Overview

In network process, WebStorage data is managed by WebKit::StorageManager class. Each StorageManager owns one or
many StorageNameSpaces, and each StorageNamespace owns one or more StorageAreas. Each StorageArea corresponds
to one storage map (one localStorage or sessionStorage object), using either a SQLite database or a in-memory
map as backend. Now that we have NetworkStorageManager, which manages storage by origin. We can merge
StorageManager with NetworkStorageManager, since localStorage and sessionStorage are not shared between
different origins.


### Hierarchy

* NetworkStorageManager (manage storage for a session, owns one or more OriginStorageManagers)
* OriginStorageManager (manage storage for an origin, owns one LocalStorageManager and one SessionStorageManager)
* LocalStorageManager / SessionStorageManager (manage LocalStorage and SessionStorage, owns one or more
StorageAreaBases)
* MemoryStorageArea / SQLiteStorageArea (inherits StorageAreaBases; manage one local or session storage, like
Webkit::StorageArea)

![Storage Manager](../../assets/Storage%20Manager.svg)


### Notes

The StorageNamespace layer was removed. For SessionStorage, different StorageNamespaces means different web pages,
and same origin can have different sessionStorages on different pages, so we keep a StorageNamespace <=>
StorageArea map in SessionStorageManager. For LocalStorage, different StorageNamespaces means different page
groups. Our original plan was the same origin can have different localStorages in different page groups, but our
old implementation actually made all page groups point to the same database file. To keep existing behavior
that all page groups with same origin share the storage, we now keep one local StorageArea and one transient
StorageArea per LocalStorageManager.