var ReadiumSdk;
(function (ReadiumSdk) {
    var Size = (function () {
        function Size() { }
        return Size;
    })();
    ReadiumSdk.Size = Size;    
})(ReadiumSdk || (ReadiumSdk = {}));
var ReadiumSdk;
(function (ReadiumSdk) {
    var PaginationInfo = (function () {
        function PaginationInfo(visibleColumnCount, columnGap) {
            this.visibleColumnCount = visibleColumnCount;
            this.columnGap = columnGap;
        }
        return PaginationInfo;
    })();
    ReadiumSdk.PaginationInfo = PaginationInfo;    
})(ReadiumSdk || (ReadiumSdk = {}));
var ReadiumSdk;
(function (ReadiumSdk) {
    var Reader = (function () {
        function Reader() {
            this.paginationInfo = new ReadiumSdk.PaginationInfo(1, 20);
            this.viewPortSize = new ReadiumSdk.Size();
        }
        Reader.getInstance = function getInstance() {
            if(Reader.instance == null) {
                Reader.instance = new Reader();
            }
            return Reader.instance;
        };
        Reader.prototype.getEpubContentDocument = function () {
            var iframe = document.getElementById("epubContentIframe");
            return iframe.contentDocument;
        };
        Reader.prototype.openPage = function (pageIndex) {
            if(pageIndex >= 0 && pageIndex < this.paginationInfo.pageCount) {
                this.paginationInfo.currentPage = pageIndex;
                this.displayCurrentPage();
            }
        };
        Reader.prototype.moveNextPage = function () {
            console.log("OnNextPage()");
            if(this.paginationInfo.currentPage < this.paginationInfo.pageCount - 1) {
                this.paginationInfo.currentPage++;
                this.displayCurrentPage();
            }
        };
        Reader.prototype.movePrevPage = function () {
            console.log("OnPrevPage()");
            if(this.paginationInfo.currentPage > 0) {
                this.paginationInfo.currentPage--;
                this.displayCurrentPage();
            }
        };
        Reader.prototype.displayCurrentPage = function () {
            if(this.paginationInfo.currentPage < 0 || this.paginationInfo.currentPage >= this.paginationInfo.pageCount) {
                this.updateLauncher(0, 0);
                return;
            }
            var shift = this.paginationInfo.currentPage * (this.viewPortSize.width + this.paginationInfo.columnGap);
            var $epubHtml = $("html", this.getEpubContentDocument());
            $epubHtml.css("left", -shift + "px");
            this.updateLauncher(this.paginationInfo.currentPage, this.paginationInfo.pageCount);
        };
        Reader.prototype.updateLauncher = function (pageIx, pageCount) {
            var launcher = window['LauncherUI'];
            if(launcher) {
                launcher.onOpenPageIndexOfPages(pageIx, pageCount);
            }
        };
        Reader.prototype.updateViewPortSize = function () {
            var newWidth = $("#key-hole").width();
            var newHeight = $("#key-hole").height();
            if(this.viewPortSize.width !== newWidth || this.viewPortSize.height !== newHeight) {
                this.viewPortSize.width = newWidth;
                this.viewPortSize.height = newHeight;
                return true;
            }
            return false;
        };
        Reader.prototype.updatePagination = function () {
            var _this = this;
            this.paginationInfo.columnWidth = (this.viewPortSize.width - this.paginationInfo.columnGap * (this.paginationInfo.visibleColumnCount - 1)) / this.paginationInfo.visibleColumnCount;
            var contentDoc = this.getEpubContentDocument();
            $("html", contentDoc).css("width", this.viewPortSize.width);
            $("html", contentDoc).css("-webkit-column-width", this.paginationInfo.columnWidth + "px");
            this.displayCurrentPage();
            setTimeout(function () {
                console.log("Set num of viewports");
                var columnizedContentWidth = $("html", contentDoc)[0].scrollWidth;
                $("#epubContentIframe").css("width", columnizedContentWidth);
                _this.paginationInfo.pageCount = Math.round(columnizedContentWidth / _this.viewPortSize.width);
                if(_this.paginationInfo.currentPage >= _this.paginationInfo.pageCount) {
                    _this.paginationInfo.currentPage = _this.paginationInfo.pageCount - 1;
                }
                _this.displayCurrentPage();
            }, 100);
        };
        return Reader;
    })();
    ReadiumSdk.Reader = Reader;    
    $(function () {
        var reader = Reader.getInstance();
        $("#epubContentIframe").on("load", function (e) {
            var $epubHtml = $("html", reader.getEpubContentDocument());
            $epubHtml.css("height", "100%");
            $epubHtml.css("position", "absolute");
            $epubHtml.css("-webkit-column-axis", "horizontal");
            $epubHtml.css("-webkit-column-gap", reader.paginationInfo.columnGap + "px");
            reader.paginationInfo.currentPage = 0;
            reader.updateViewPortSize();
            reader.updatePagination();
        });
        $(window).resize(function (e) {
            if(reader.updateViewPortSize()) {
                reader.updatePagination();
            }
        });
    });
})(ReadiumSdk || (ReadiumSdk = {}));
