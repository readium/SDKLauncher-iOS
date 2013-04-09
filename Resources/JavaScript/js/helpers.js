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


ReadiumSDK.Helpers.Rect = function(left, top, width, height) {

    this.left = left;
    this.top = top;
    this.width = width;
    this.height = height;

    this.right = function() {
        return this.left + this.width;
    }

    this.bottom = function() {
        return this.top + this.height;
    }

    this.isOverlap = function(rect, tolerance) {

        if(tolerance == undefined) {
            tolerance = 0;
        }

        if ( rect.right() < this.left + tolerance
          || rect.left > this.right() - tolerance
          || rect.bottom() < this.top + tolerance
          || rect.top > this.bottom() - tolerance) {

            return false;
        }

        return true;
    }
}

ReadiumSDK.Helpers.Rect.fromElement = function($element) {

    var offset = $element.offset();
    return new ReadiumSDK.Helpers.Rect(offset.left, offset.top, $element.width(), $element.height());

}