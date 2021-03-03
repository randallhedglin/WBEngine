package com.wb.software
{
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	internal final class WBSaveBitmapDataAsPng
	{
		public static function save(bmpData  :BitmapData,
									filename :String,
									width    :int = 0,
									height   :int = 0) :void
		{
			// set bounding rect
			var rect :Rectangle = new Rectangle(0, 0,
												width  ? width  : bmpData.width,
												height ? height : bmpData.height);
			
			// encode to byte array
			var pngData :ByteArray = bmpData.encode(rect,
													new PNGEncoderOptions());
			
			// create file object
			var file :File = new File(filename);
			
			// create file stream
			var fileStream :FileStream = new FileStream();
			
			// open file stream for output
			fileStream.open(file, FileMode.WRITE);
			
			// write encoded image
			fileStream.writeBytes(pngData);
			
			// close file streamn
			fileStream.close();
		}
	}
}