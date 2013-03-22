
///<reference path="jquery.d.ts" />
///<reference path='size.ts' />
///<reference path='pagination_info.ts' />

module ReadiumSdk {

    export class Reader {

        private static instance : Reader;     

        public viewPortSize : Size;
        public paginationInfo : PaginationInfo;

        public static getInstance() : Reader {

            if(instance == null) {
                instance = new Reader();
            }

            return instance;
        }  

        constructor()
        {
            this.paginationInfo = new PaginationInfo(1, 20);
            this.viewPortSize = new Size();
            
        }

        public getEpubContentDocument()
        {
            var iframe = <HTMLIFrameElement>document.getElementById("epubContentIframe");
            return iframe.contentDocument;
        }

        public openPage(pageIndex : number)
        {
            if(pageIndex >= 0 && pageIndex < this.paginationInfo.pageCount) {
                this.paginationInfo.currentPage = pageIndex;
                this.displayCurrentPage();
            }
        }


        public moveNextPage() : void
        {
            console.log("OnNextPage()");

            if(this.paginationInfo.currentPage < this.paginationInfo.pageCount - 1) {
                this.paginationInfo.currentPage++;
                this.displayCurrentPage();
            }
        }

        public movePrevPage() : void
        {
            console.log("OnPrevPage()");

            if(this.paginationInfo.currentPage > 0) {
                this.paginationInfo.currentPage--;
                this.displayCurrentPage();
            }

        }

        private displayCurrentPage() : void
        {
            if(this.paginationInfo.currentPage < 0 || this.paginationInfo.currentPage >= this.paginationInfo.pageCount) {

                this.updateLauncher(0, 0);
                return;
            }

            var shift = this.paginationInfo.currentPage * (this.viewPortSize.width + this.paginationInfo.columnGap);

            var $epubHtml = $("html", this.getEpubContentDocument());
            $epubHtml.css("left", -shift + "px");

            this.updateLauncher(this.paginationInfo.currentPage, this.paginationInfo.pageCount);
        }

        private updateLauncher(pageIx: number, pageCount: number) {
            window.location.href = "epubobjc:setPageIndexAndPageCount/" + pageIx + "/" + pageCount;
        }

        public updateViewPortSize() : bool
        {
            var newWidth = $("#key-hole").width();
            var newHeight = $("#key-hole").height();

            if(this.viewPortSize.width !== newWidth || this.viewPortSize.height !== newHeight){

                this.viewPortSize.width = newWidth;
                this.viewPortSize.height = newHeight;
                return true;
            }

            return false;
        };


        updatePagination() : void
        {
            this.paginationInfo.columnWidth = (this.viewPortSize.width - this.paginationInfo.columnGap * (this.paginationInfo.visibleColumnCount  -1)) / this.paginationInfo.visibleColumnCount;

            var contentDoc = this.getEpubContentDocument();
            $("html", contentDoc).css("width", this.viewPortSize.width);
            $("html", contentDoc).css("-webkit-column-width", this.paginationInfo.columnWidth + "px");

            this.displayCurrentPage();

            //TODO it takes time for layout engine to arrange columns we waite
            //it would be better to react on layout column reflow finished event
            setTimeout( () => {
                console.log("Set num of viewports");
                var columnizedContentWidth = $("html", contentDoc)[0].scrollWidth;
                $("#epubContentIframe").css("width", columnizedContentWidth);
                this.paginationInfo.pageCount = Math.round(columnizedContentWidth / this.viewPortSize.width);

                if(this.paginationInfo.currentPage >= this.paginationInfo.pageCount) {
                    this.paginationInfo.currentPage = this.paginationInfo.pageCount - 1;
                }

                this.displayCurrentPage();
            }, 100);

        }
    }


    $(() => {

        var reader = Reader.getInstance();
        
         // When the iframe has been loaded, paginate the epub content document
        $("#epubContentIframe").on("load", (e) => {

            var $epubHtml = $("html", reader.getEpubContentDocument());

            $epubHtml.css("height", "100%");
            $epubHtml.css("position", "absolute");
            $epubHtml.css("-webkit-column-axis", "horizontal");
            $epubHtml.css("-webkit-column-gap", reader.paginationInfo.columnGap + "px");

/////////
//Columns Debugging
//                    $epubHtml.css("-webkit-column-rule-color", "red");
//                    $epubHtml.css("-webkit-column-rule-style", "dashed");
//                    $epubHtml.css("background-color", '#b0c4de');
/////////

            reader.paginationInfo.currentPage = 0;
            reader.updateViewPortSize();
            reader.updatePagination();

        });

        $(window).resize((e) => {

            if (reader.updateViewPortSize()) {

               reader.updatePagination();
           }
        });
    });

}
