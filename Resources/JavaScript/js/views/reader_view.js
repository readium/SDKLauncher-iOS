
//  LauncherOSX
//
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


//noinspection JSUnusedGlobalSymbols
ReadiumSDK.Views.ReaderView = Backbone.View.extend({

    el: '#epubContentIframe',

    lastViewPortSize : {
        width: undefined,
        height: undefined
    },

    paginationInfo : {

        visibleColumnCount : 1,
        columnGap : 20,
        pageCount : 0,
        currentPage : 0,
        columnWidth : undefined,
        pageOffset : 0
    },

    events: {

        "resize window" : "onViewportResize",
        "load" : "onIFrameLoad"
    },

    initialize: function() {

        this.navigation = new ReadiumSDK.Views.CfiNavigationLogic({paginationInfo: this.paginationInfo});

        this.$viewport = $("#viewport");

        //for code readability
        this.$iframe = this.$el;


        //event with namespace for clean unbinding
        $(window).on("resize.ReadiumSDK.readerView", _.bind(this.onViewportResize, this));

    },

    remove: function() {

        $(window).off("resize.ReadiumSDK.readerView");

        //base remove
        Backbone.View.prototype.remove.call(this);
    },


    onViewportResize: function() {

        if(this.updateViewportSize()) {
            this.updatePagination();
        }

    },

    registerTriggers: function (doc) {
        $('trigger', doc).each(function() {
            var trigger = new ReadiumSDK.Models.Trigger(this);
            trigger.subscribe(doc);

        });
    },

    onIFrameLoad : function() {

        var epubContentDocument = this.$iframe[0].contentDocument;
        this.$epubHtml = $("html", epubContentDocument);

        this.$epubHtml.css("height", "100%");
        this.$epubHtml.css("position", "absolute");
        this.$epubHtml.css("-webkit-column-axis", "horizontal");
        this.$epubHtml.css("-webkit-column-gap", this.paginationInfo.columnGap + "px");

/////////
//Columns Debugging
//                    $epubHtml.css("-webkit-column-rule-color", "red");
//                    $epubHtml.css("-webkit-column-rule-style", "dashed");
//                    $epubHtml.css("background-color", '#b0c4de');
/////////

        this.paginationInfo.currentPage = 0;
        this.updateViewportSize();
        this.updatePagination();

        this.applySwitches(epubContentDocument);
        this.registerTriggers(epubContentDocument);


    },

    render: function(){

        if(this.paginationInfo.currentPage < 0 || this.paginationInfo.currentPage >= this.paginationInfo.pageCount) {

            this.trigger("PageChanged", 0, 0);
            return;
        }

        this.paginationInfo.pageOffset = this.paginationInfo.currentPage * (this.lastViewPortSize.width + this.paginationInfo.columnGap);

        this.$epubHtml.css("left", -this.paginationInfo.pageOffset + "px");

        this.trigger("PageChanged", this.paginationInfo.currentPage, this.paginationInfo.pageCount);

    },

    updateViewportSize: function() {

        var newWidth = this.$viewport.width();
        var newHeight = this.$viewport.height();

        if(this.lastViewPortSize.width !== newWidth || this.lastViewPortSize.height !== newHeight){

            this.lastViewPortSize.width = newWidth;
            this.lastViewPortSize.height = newHeight;
            return true;
        }

        return false;
    },

    // Description: Parse the epub "switch" tags and hide
    // cases that are not supported
    applySwitches: function(dom) {

        // helper method, returns true if a given case node
        // is supported, false otherwise
        var isSupported = function(caseNode) {

            var ns = caseNode.attributes["required-namespace"];
            if(!ns) {
                // the namespace was not specified, that should
                // never happen, we don't support it then
                console.log("Encountered a case statement with no required-namespace");
                return false;
            }
            // all the xmlns's that readium is known to support
            // TODO this is going to require maintanence
            var supportedNamespaces = ["http://www.w3.org/1998/Math/MathML"];
            return _.include(supportedNamespaces, ns);
        };

        $('switch', dom).each( function() {

            // keep track of whether or now we found one
            var found = false;

            $('case', this).each(function() {

                if( !found && isSupported(this) ) {
                    found = true; // we found the node, don't remove it
                }
                else {
                    $(this).remove(); // remove the node from the dom
//                    $(this).prop("hidden", true);
                }
            });

            if(found) {
                // if we found a supported case, remove the default
                $('default', this).remove();
//                $('default', this).prop("hidden", true);
            }
        })
    },

    movePrevPage:  function () {

        console.log("OnPrevPage()");

        if(this.paginationInfo.currentPage > 0) {
            this.paginationInfo.currentPage--;
            this.render();
        }

    },

    moveNextPage: function () {

        console.log("OnNextPage()");

        if(this.paginationInfo.currentPage < this.paginationInfo.pageCount - 1) {
            this.paginationInfo.currentPage++;
            this.render();
        }
    },

    openPage: function(pageIndex) {

        if (pageIndex >= 0 && pageIndex < this.paginationInfo.pageCount) {
            this.paginationInfo.currentPage = pageIndex;
            this.render();
        }

    },

    updatePagination: function() {

        if(!this.$epubHtml) {
            return;
        }


        this.paginationInfo.columnWidth =
                (this.lastViewPortSize.width - this.paginationInfo.columnGap * (this.paginationInfo.visibleColumnCount - 1)) / this.paginationInfo.visibleColumnCount;

        this.$epubHtml.css("width", this.lastViewPortSize.width);
        this.$epubHtml.css("-webkit-column-width", this.paginationInfo.columnWidth + "px");

        //we will render on timer but rendering before gives better visual experience
        this.render();

        var self = this;
        //TODO it takes time for layout engine to arrange columns we waite
        //it would be better to react on layout column reflow finished event
        setTimeout(function(){

            var columnizedContentWidth = self.$epubHtml[0].scrollWidth;
            self.$iframe.css("width", columnizedContentWidth);
            self.paginationInfo.pageCount =  Math.round(columnizedContentWidth / self.lastViewPortSize.width);

            if(self.paginationInfo.currentPage >= self.paginationInfo.pageCount) {
                self.paginationInfo.currentPage = self.paginationInfo.pageCount - 1;
            }

            self.trigger("PaginationReady");
            self.render();


        }, 100);

    },

    getFirstVisibleElementCfi: function(){

        return this.navigation.getFirstVisibleElementCfi();
    },

    getPageForElementCfi: function(cfi) {

        return this.navigation.getPageForElementCfi(cfi);

    },

    getPageForElementId: function(id) {

        return this.navigation.getPageForElementId(id);
    }

});
