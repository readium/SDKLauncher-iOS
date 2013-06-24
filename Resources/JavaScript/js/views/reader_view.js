//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

ReadiumSDK.Views.ReaderView = Backbone.View.extend({

    el: 'body',
    currentView: undefined,
    package: undefined,
    spine: undefined,

    render: function() {

        if(!this.package || ! this.spine) {
            return;
        }

        if(this.package.isFixedLayout()) {

            this.currentView = new ReadiumSDK.Views.FixedView({spine:this.spine});
        }
        else {

            this.currentView = new ReadiumSDK.Views.ReflowableView({spine:this.spine});
        }

        this.$el.append(this.currentView.render().$el);

        var self = this;
        this.currentView.on("PaginationChanged", function(){

            var paginationReportData = self.currentView.getPaginationInfo();
            ReadiumSDK.HostAppFeedback.ReportPageChanged(paginationReportData);

        });

    },

    /**
     * Triggers the process of opening the book and requesting resources specified in the packageData
     *
     * @param {ReadiumSDK.Models.PackageData} packageData DTO Object hierarchy of Package, Spine, SpineItems passed by
     * host application to the reader
     * @param {ReadiumSDK.Models.PageOpenRequest|undefined} openPageRequestData Optional parameter specifying
     * on what page book should be open when it is loaded. If nothing is specified book will be opened on the first page
     */
    openBook: function(packageData, openPageRequestData) {

        this.reset();

        this.package = new ReadiumSDK.Models.Package({packageData: packageData});
        this.spine = this.package.spine;

        this.render();

        if(openPageRequestData) {

            if(openPageRequestData.idref) {

                if(openPageRequestData.spineItemPageIndex) {
                    this.openSpineItemPage(openPageRequestData.idref, openPageRequestData.spineItemPageIndex);
                }
                else if(openPageRequestData.elementCfi) {
                    this.openSpineItemElementCfi(openPageRequestData.idref, openPageRequestData.elementCfi);
                }
                else {
                    this.openSpineItemPage(openPageRequestData.idref, 0);
                }
            }
            else if(openPageRequestData.contentRefUrl && openPageRequestData.sourceFileHref) {
                this.openContentUrl(openPageRequestData.contentRefUrl, openPageRequestData.sourceFileHref);
            }
            else {
                console.log("Invalid page request data: idref required!");
            }
        }
        else {// if we where not asked to open specific page we will open the first one

            var spineItem = this.spine.first();
            if(spineItem) {
                var pageOpenRequest = new ReadiumSDK.Models.PageOpenRequest(spineItem);
                pageOpenRequest.setFirstPage();
                this.currentView.openPage(pageOpenRequest);
            }

        }

    },

    /**
     *Flips the page from left to right
     */
    openPageLeft: function() {

        if(this.package.spine.isLeftToRight()) {
            this.openPagePrev();
        }
        else {
            this.openPageNext();
        }
    },

    /**
     * Flips the page from right to left
     */
    openPageRight: function() {

        if(this.package.spine.isLeftToRight()) {
            this.openPageNext();
        }
        else {
            this.openPagePrev();
        }

    },

    /**
     * Opens the next page. Takes to account the page progression direction to decide to flip page left or right
     */
    openPageNext: function() {
        this.currentView.openPageNext();
    },

    /**
     * Opens the previews page. Takes to account the page progression direction to decide to flip page left or right
     */
    openPagePrev: function() {
        this.currentView.openPagePrev();
    },

    reset: function() {

        if(this.currentView) {

            this.currentView.off("PaginationChanged");
            this.currentView.remove();
        }
    },

    getSpineItem: function(idref) {

        if(!idref) {

            console.log("idref parameter value missing!");
            return undefined;
        }

        var spineItem = this.spine.getItemById(idref);
        if(!spineItem) {
            console.log("Spine item with id " + idref + " not found!");
            return undefined;
        }

        return spineItem;

    },

    /**
     * Opens the page of the spine item with element with provided cfi
     *
     * @param {string} idref Id of the spine item
     * @param {string} elementCfi CFI of the element to be shown
     */
    openSpineItemElementCfi: function(idref, elementCfi) {

        var spineItem = this.getSpineItem(idref);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.PageOpenRequest(spineItem);
        if(elementCfi) {
            pageData.setElementCfi(elementCfi);
        }

        this.currentView.openPage(pageData);
    },

    /**
     *
     * Opens specified page index of the current spine item
     *
     * @param {number} pageIndex Zero based index of the page in the current spine item
     */
    openPage: function(pageIndex) {

        if(!this.currentView) {
            return;
        }

        var pageRequest;
        if(this.package.isFixedLayout()) {
            var spineItem = this.package.spine.items[pageIndex];
            if(!spineItem) {
                return;
            }

            pageRequest = new ReadiumSDK.Models.PageOpenRequest(spineItem);
            pageRequest.setPageIndex(0);
        }
        else {

            pageRequest = new ReadiumSDK.Models.PageOpenRequest(undefined);
            pageRequest.setPageIndex(pageIndex);

        }

        this.currentView.openPage(pageRequest);
    },

    /**
     *
     * Opens page index of the spine item with idref provided
     *
     * @param {string} idref Id of the spine item
     * @param {number} pageIndex Zero based index of the page in the spine item
     */
    openSpineItemPage: function(idref, pageIndex) {

        var spineItem = this.getSpineItem(idref);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.PageOpenRequest(spineItem);
        if(pageIndex) {
            pageData.setPageIndex(pageIndex);
        }

        this.currentView.openPage(pageData);
    },

    /**
     * Opens the content document specified by the url
     *
     * @param {string} contentRefUrl Url of the content document
     * @param {string | undefined} sourceFileHref Url to the file that contentRefUrl is relative to. If contentRefUrl is
     * relative ot the source file that contains it instead of the package file (ex. TOC file) We have to know the
     * sourceFileHref to resolve contentUrl relative to the package file.
     *
     */
    openContentUrl: function(contentRefUrl, sourceFileHref) {

        var combinedPath = ReadiumSDK.Helpers.ResolveContentRef(contentRefUrl, sourceFileHref);


        var hashIndex = combinedPath.indexOf("#");
        var hrefPart;
        var elementId;
        if(hashIndex >= 0) {
            hrefPart = combinedPath.substr(0, hashIndex);
            elementId = combinedPath.substr(hashIndex + 1);
        }
        else {
            hrefPart = combinedPath;
            elementId = undefined;
        }

        var spineItem = this.spine.getItemByHref(hrefPart);

        if(!spineItem) {
            return;
        }

        var pageData = new ReadiumSDK.Models.PageOpenRequest(spineItem)
        if(elementId){
            pageData.setElementId(elementId);
        }

        this.currentView.openPage(pageData);
    },

    /**
     *
     * Returns the bookmark associated with currently opened page.
     *
     * @returns {string} Stringified ReadiumSDK.Models.BookmarkData object.
     */
    bookmarkCurrentPage: function() {
        return JSON.stringify(this.currentView.bookmarkCurrentPage());
    }

});