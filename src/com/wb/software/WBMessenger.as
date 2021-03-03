package com.wb.software
{
	import flash.display.Loader;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;

	internal class WBMessenger
	{
		// swf metadata values
		public var m_swfWidth     :int = 0;
		public var m_swfHeight    :int = 0;
		public var m_swfFrameRate :int = 0;
		
		// WBMessenger() -- default constructor
		public function WBMessenger(swfWidth     :int,
									swfHeight    :int,
									swfFrameRate :int)
		{
			// save metadata values
			m_swfWidth     = swfWidth;
			m_swfHeight    = swfHeight;
			m_swfFrameRate = swfFrameRate;
		}
		
		// createLoader() -- create loader object for given path
		public function createLoader(path :String) :Loader
		{
			// create new loader
			var loader :Loader = new Loader();
			
			// set error listeners
			loader.contentLoaderInfo.addEventListener(AsyncErrorEvent   .ASYNC_ERROR,    onLoaderError);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent      .IO_ERROR,       onLoaderError);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderError);
			
			// set progress listener
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoaderProgress);
			
			// set init listener
			loader.contentLoaderInfo.addEventListener(Event.INIT, onLoaderComplete);
			
			// create loader context
			var loaderContext :LoaderContext = new LoaderContext(false,
											  				 	 ApplicationDomain.currentDomain,
											  				 	 null);
			
			// create url request
			var url :URLRequest = new URLRequest(path);
			
			// load the asset
			loader.load(url, loaderContext);
			
			// ok
			return(loader);
		}
		
		// onLoaderComplete() -- loader has finished loading an object
		private function onLoaderComplete(e :Event) :void
		{
			// inform app
			send("loadComplete");
		}

		// onLoaderError() -- loader has encountered an error
		private function onLoaderError(e :Event) :void
		{
			// report error
			send("messageBox",
				 "com.wb.software.WBMessenger.createLoader()",
				 "Failed to access application resource library");
		}

		// onLoaderProgress() -- loader has reported its progress
		private function onLoaderProgress(e :ProgressEvent) :void
		{
			// pass to app
			send("loadProgress", e.bytesLoaded, e.bytesTotal);
		}

		// send() -- communicate with owner of this object
		public function send(message :String, ...argv) :int
		{
			// this function is to be overridden in a derived class
			throw new Error("com.wb.software.WBMessenger.send(): " +
				"Function must be overridden in a derived class");
			
			// ok
			return(0);
		}
	}
}