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

ReadiumSDK.HostAppFeedback = function(reader) {

    reader.on("PageChanged", function(pageIx, pageCount){
        window.location.href = "epubobjc:setPageIndexAndPageCount/" + pageIx + "/" + pageCount;
    }),

    reader.on("PaginationReady", function() {

        // In practice, the following does not work because a PageChanged event happens at
        // nearly the same time, which prevents the web view from seeing the href update.
        // A PageChanged event with a non-zero page count serves the same purpose, so that's
        // what we check for in Objective-C.

        // window.location.href = "epubobjc:onPaginationScriptingReady";
    });

};