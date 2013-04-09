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

ReadiumSDK.Views.CfiNavigationLogic = Backbone.View.extend({

    el: '#epubContentIframe',

    initialize: function () {

        this.$viewport = $("#viewport");

    },

    getRootElement: function(){

        return this.$el[0].contentDocument.documentElement

    },

    //we look for text and images
    findFirstVisibleElement: function () {

        var $elements;
        var $firstVisibleTextNode = null;

        var viewportRect = new ReadiumSDK.Helpers.Rect(0, 0, this.$viewport.width(), this.$viewport.height());

        $elements = $("body", this.getRootElement()).find(":not(iframe)").filter(function () {
            if (this.nodeType === Node.TEXT_NODE || this.nodeName.toLowerCase() === 'img') {
                return true;
            } else {
                return false;
            }
        });

        // Find the first visible text node
        $.each($elements, function() {

            var $element;

            if(this.nodeType === Node.TEXT_NODE)  { //text node
                // Heuristic to find a text node with actual text
                var nodeText = this.nodeValue.replace(/\n/g, "");
                nodeText = nodeText.replace(/ /g, "");

                if(nodeText.length > 0) {
                    $element = $(this).parent();
                }
                else {
                    return true; //next element
                }
            }
            else {
                $element = $(this); //image
            }

            var elementRect = ReadiumSDK.Helpers.Rect.fromElement($element);

            if (viewportRect.isOverlap(elementRect, 5)) {

                $firstVisibleTextNode = $element;

                // Break the loop
                return false;
            }
        });

        return $firstVisibleTextNode;
    },

    getFirstVisibleElementCfi: function() {

        var $element = this.findFirstVisibleElement();

        if(!$element) {
            console.log("Could not generate CFI no visible element on page");
            return;
        }

        var cfi = EPUBcfi.Generator.generateElementCFIComponent($element[0]);

        var invisiblePart = -$element.offset().top;

        var percent = 0;
        var height = $element.height();
        if(invisiblePart > 0 && height > 0) {
             percent = Math.ceil(invisiblePart * 100 / height);
        }

        if(cfi[0] == "!") {
            cfi = cfi.substring(1);
        }

        return cfi + "@0:" + percent;
    },

    getPageForElementCfi: function(cfi) {

        var contentDoc = this.$el[0].contentDocument;
        var cfiParts = this.splitCfi(cfi);

        var wrappedCfi = "epubcfi(" + cfiParts.cfi + ")";
        var $element = EPUBcfi.Interpreter.getTargetElementWithPartialCFI(wrappedCfi, contentDoc);

        if(!$element || $element.length == 0) {
            console.log("Can't find element for CFI: " + cfi);
            return;
        }

        return this.getPageForElement($element, cfiParts.x, cfiParts.y);
    },

    //x,y point on element
    getPageForElement: function($element, x, y) {

        var PERCENT_ROUNDING_TOLERANCE = 1;

        if($element[0].nodeType === Node.TEXT_NODE) { //text
            $element = $element.parent();
        }

        var pagination = this.options.paginationInfo;

        var elementRect = ReadiumSDK.Helpers.Rect.fromElement($element);
        var viewportRect = new ReadiumSDK.Helpers.Rect(0, 0, this.$viewport.width(), this.$viewport.height());

        var elLeft = elementRect.left + pagination.pageOffset;

        var page = Math.floor(elLeft / (pagination.columnWidth + pagination.columnGap));

        var posInElement = Math.ceil(elementRect.top + y * elementRect.height / 100);

        var overFlow;

        if(posInElement + PERCENT_ROUNDING_TOLERANCE < viewportRect.top ) {
            overFlow = Math.abs(viewportRect.top - posInElement);
            page = page - Math.ceil(overFlow / viewportRect.height);
        }
        else if (posInElement - PERCENT_ROUNDING_TOLERANCE > viewportRect.bottom()) {
            overFlow = Math.abs(posInElement - viewportRect.bottom());
            page = page + Math.ceil(overFlow / viewportRect.height);
        }

        return page;
    },

    getPageForElementId: function(id) {

        var contentDoc = this.$el[0].contentDocument;


        var $element = $("#" + id, contentDoc);
        if($element.length == 0) {
            return -1;
        }

        return this.getPageForElement($element, 0, 0);
    },

    splitCfi: function(cfi) {

        var ret = {
            cfi: "",
            x: 0,
            y: 0
        };

        var ix = cfi.indexOf("@");

        if(ix != -1) {
            var terminus = cfi.substring(ix + 1);

            var colIx = terminus.indexOf(":");
            if(colIx != -1) {
                ret.x = parseInt(terminus.substr(0, colIx));
                ret.y = parseInt(terminus.substr(colIx + 1));
            }
            else {
                console.log("Unexpected terminating step format");
            }

            ret.cfi = cfi.substring(0, ix);
        }
        else {

            ret.cfi = cfi;
        }

        return ret;
    }

});