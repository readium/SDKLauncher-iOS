Readium-SDKLauncher-iOS
=======================



## Running the launcher

This project depends on the [Readium SDK](https://github.com/readium/readium-sdk). You can get it as a git submodule:

```
git clone git@github.com:readium/SDKLauncher-iOS.git
cd SDKLauncher-iOS
git submodule init
git submodule update
```


## Importing the reader in your own project

* Define a dependency to ReadiumSDK by adding a submodule in a Framework directory :

```
git submodule add https://github.com/readium/readium-sdk.git Framework/readium-sdk
git submodule init
git submodule update
```


* Add the ReadiumSDK as a static library to your project

Drag and drop the readium project inside your xcode project, the xcode project is located in :

```
/readium-sdk/Platform/Apple/ePub3.xcodeproj
```



* Add the readium static library to the link Binary with libraries :

```
libePub3-iOS.a
```



* Update your Header Search Path :

```
${SDKROOT}/usr/include/libxml2
readium-sdk/ePub3 (choose recursive)
```



* Add the following frameworks in your project :

```
CFNetwork
libxml2
libz
```


* You can now build the Readium iOS classes, don't forget to set the NSURLProtocols in your project (in your app delegate for example)

```
[NSURLProtocol registerClass:[BundleURLProtocol class]];
[NSURLProtocol registerClass:[EPubURLProtocol class]];
```


