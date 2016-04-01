# SDKLauncher-iOS (LCP-enabled)

## Overview

This fork of Readium SDKLauncher-iOS uses [Mantano's LCP client library](https://github.com/Mantano/mantano-lcp-client) to be able to:

 * read LCP protected books (including videos with random access),
 * download a publication from a standalone LCPL file,
 * safely store user keys.
 
## Instructions

### Root Certificate

You need to put your Root Certificate in `Resources/LCP Root Certificate.crt` to be able to read LCP protected EPUB. The Root Certificates are delivered by the Readium Foundation to licensees.

As an alternative, you can use your own self-signed certificate paired with a LCP server (see: Installing a LCP Server).

### Using the App

Add LCP books and LCPL standalone files to the Launcher using [iTunes File Sharing](https://support.apple.com/en-us/HT201301).

You can open a LCP book the same way you would with a non-protected book. If the passphrase is not already saved in the secure storage, the launcher will prompt you to enter it.

To acquire a book using a LCPL file, select it. The download progression will be displayed over the row, and then the protected book with replace the LCPL file.
You can cancel an acquisition by tapping again on the LCPL file in the list.



### Installing a LCP Server

You need your own LCP server to produce LCP protected books (eg. [Readium LCP server](https://github.com/readium/readium-lcp-server)).

Create your own x509 V3 self-signed certificate using the following commands:

    openssl genrsa -des3 -out lcp.pem 1024
    
    openssl req -new -key lcp.pem -out lcp.csr

    echo "[v3_ca]\nbasicConstraints = CA:TRUE\nsubjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid:always,issuer:always" > lcp.ext
    
    openssl x509 -req -extensions v3_ca -extfile lcp.ext -days 10950 -in lcp.csr -signkey lcp.pem -out lcp.crt

Use the generated `lcp.crt` file as the Root Certificate for the Launcher, and as the Content Provider Certificate for your LCP server.
