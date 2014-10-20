//  LauncherOSX
//
//  Created by Boris Schneiderman.
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

ReadiumSDK.HostAppFeedback = function() {
	ReadiumSDK.on(ReadiumSDK.Events.READER_INITIALIZED, function() {
                  
        window.navigator.epubReadingSystem.name = "Launcher-iOS";
        window.navigator.epubReadingSystem.version = "0.0.1";
                  
		ReadiumSDK.reader.on(ReadiumSDK.Events.PAGINATION_CHANGED, this.onPaginationChanged, this);
		ReadiumSDK.reader.on(ReadiumSDK.Events.SETTINGS_APPLIED, this.onSettingsApplied, this);
        ReadiumSDK.reader.on(ReadiumSDK.Events.MEDIA_OVERLAY_STATUS_CHANGED, this.onMediaOverlayStatusChanged, this);
        ReadiumSDK.reader.on(ReadiumSDK.Events.MEDIA_OVERLAY_TTS_SPEAK, this.onMediaOverlayTTSSpeak, this);
        ReadiumSDK.reader.on(ReadiumSDK.Events.MEDIA_OVERLAY_TTS_STOP, this.onMediaOverlayTTSStop, this);
        
		window.location.href = "epubobjc:readerDidInitialize";
	}, this);

	this.onPaginationChanged = function(pageChangeData) {

        pageChangeData.paginationInfo.canGoLeft_ = pageChangeData.paginationInfo.canGoLeft();
        pageChangeData.paginationInfo.canGoRight_ = pageChangeData.paginationInfo.canGoRight();

		window.location.href = "epubobjc:pageDidChange?q=" +
			encodeURIComponent(JSON.stringify(pageChangeData.paginationInfo));
	};

	this.onSettingsApplied = function() {
		window.location.href = "epubobjc:settingsDidApply";
	};

    this.onMediaOverlayStatusChanged = function(status) {
        window.location.href = "epubobjc:mediaOverlayStatusDidChange?q=" +
			encodeURIComponent(JSON.stringify(status));
    };

    this.onMediaOverlayTTSSpeak = function(tts) {
        window.location.href = "epubobjc:mediaOverlayTTSDoSpeak?q=" +
			encodeURIComponent(JSON.stringify(tts));
    };

    this.onMediaOverlayTTSStop = function() {
		window.location.href = "epubobjc:mediaOverlayTTSDoStop";
    };
}();
