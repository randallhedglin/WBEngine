package com.wb.software
{
	import com.adobe.utils.v3.AGALMiniAssembler;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.display.StageQuality;
	import flash.display.StageScaleMode;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DBufferUsage;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.events.TouchEvent;
	import flash.geom.Rectangle;
	import flash.net.SharedObject;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.ui.Multitouch;
	import flash.ui.MultitouchInputMode;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	internal class WBEngine
	{
		// stored objects
		protected var m_sprite    :Sprite      = null;
		protected var m_stage     :Stage       = null;
		protected var m_messenger :WBMessenger = null;
		protected var m_launchImg :Bitmap	   = null;
		protected var m_stage3D   :Stage3D     = null;
		protected var m_context3D :Context3D   = null;
		
		// stored data
		protected var m_osFlag        :int    = 0;
		protected var m_appTitle      :String = null;
		protected var m_longestSide   :int    = 0;
		protected var m_maxDisplayRes :int    = 0;
		protected var m_orientation   :int    = 0;
		protected var m_baseAspect    :Number = 0;
		protected var m_extAspect     :Number = 0;
		protected var m_frameRate     :int    = 0;
		protected var m_frameDelay    :int    = 0;
		protected var m_frameSkipTick :int    = 0;
		protected var m_bkgColor      :uint   = 0;
		
		// swf metadata values
		protected var m_swfWidth     :int = 0;
		protected var m_swfHeight    :int = 0;
		protected var m_swfFrameRate :int = 0;
		protected var m_swfWidth2    :int = 0; // width / 2
		protected var m_swfHeight2   :int = 0; // height / 2
		
		// background color components
		protected var m_bkgColorRed   :Number = 0;
		protected var m_bkgColorGreen :Number = 0;
		protected var m_bkgColorBlue  :Number = 0;
		
		// base render field
		protected var m_baseX       :Number = 0; // will always be 0
		protected var m_baseY       :Number = 0; // will always be 0
		protected var m_baseWidth   :Number = 0;
		protected var m_baseHeight  :Number = 0;
		protected var m_baseWidth2  :Number = 0; // width / 2
		protected var m_baseHeight2 :Number = 0; // height / 2
		
		// extended render field
		protected var m_extX      :Number = 0;
		protected var m_extY      :Number = 0;
		protected var m_extWidth  :Number = 0;
		protected var m_extHeight :Number = 0;
		
		// visible render edges
		protected var m_leftEdge      :Number = 0;
		protected var m_rightEdge     :Number = 0;
		protected var m_topEdge       :Number = 0;
		protected var m_bottomEdge    :Number = 0;
		protected var m_rightEdge1    :Number = 0; // right edge - 1
		protected var m_bottomEdge1   :Number = 0; // bottom edge - 1
		protected var m_visibleWidth  :Number = 0;
		protected var m_visibleHeight :Number = 0;
		
		// auxiliary sizes
		protected var m_auxWidth  :Number = 0;
		protected var m_auxHeight :Number = 0;
		
		// stage dimensions
		protected var m_stageX      :Number = 0;
		protected var m_stageY      :Number = 0;
		protected var m_stageWidth  :Number = 0;
		protected var m_stageHeight :Number = 0;
		protected var m_stageAspect :Number = 0;
		
		// viewport dimensions
		protected var m_viewportX      :Number = 0;
		protected var m_viewportY      :Number = 0;
		protected var m_viewportWidth  :Number = 0;
		protected var m_viewportHeight :Number = 0;
		
		// launch image bounds
		protected var m_boundsX      :Number = 0;
		protected var m_boundsY      :Number = 0;
		protected var m_boundsWidth  :Number = 0;
		protected var m_boundsHeight :Number = 0;
		
		// launch image render data
		protected var m_launchImgShader  :int = -1;
		protected var m_launchImgVtxBuf  :int = -1;
		protected var m_launchImgIdxBuf  :int = -1;
		protected var m_launchImgTexture :int = -1;
		protected var m_launchImgView    :int = -1;
		
		// world coordinates
		protected var m_worldX :Number = 0;
		protected var m_worldY :Number = 0;

		// view render data
		protected var m_viewShader    :int             = -1;
		protected var m_viewVtxBuf    :int             = -1;
		protected var m_viewIdxBuf    :int             = -1;
		protected var m_viewTexList   :Vector.<int>    = null;
		protected var m_viewColorList :Vector.<int>    = null;
		protected var m_viewVtxConst  :Vector.<Number> = null;
		protected var m_viewOfsX      :Number          = 0;
		protected var m_viewOfsY      :Number          = 0;
		protected var m_viewScaleX    :Number          = 0;
		protected var m_viewScaleY    :Number          = 0;
		
		// shared object (persistent data)
		protected var m_shared :SharedObject = null;
		
		// timers
		protected var m_firstUpdateTimer :Timer = null;
		protected var m_frameRateTimer   :Timer = null;
		
		// misc. flags
		protected var m_init               :Boolean = false;
		protected var m_goingNative        :Boolean = false;
		protected var m_launchImgVisible   :Boolean = false;
		protected var m_launchImg3DVisible :Boolean = false;
		protected var m_context3DReady     :Boolean = false;
		protected var m_context3DRequested :Boolean = false;
		protected var m_appActive          :Boolean = false;
		protected var m_renderWhenIdle     :Boolean = false;
		
		// render environment flags
		protected var m_graphicsErrors :Boolean = false;
		protected var m_backfaceCull   :Boolean = false;
		protected var m_frontfaceCull  :Boolean = false;
		protected var m_depthTest      :Boolean = false;
		protected var m_stencilTest    :Boolean = false;
		
		// render environment values
		protected var m_antiAliasLevel :int  = 0;
		protected var m_blendMode      :int  = 0;
		protected var m_stencilRef     :uint = 0;
		
		// render mask flags
		protected var m_maskRed   :Boolean = true;
		protected var m_maskGreen :Boolean = true;
		protected var m_maskBlue  :Boolean = true;
		protected var m_maskAlpha :Boolean = true;
		
		// shader counters
		protected var m_numShaders :int = 0;
		protected var m_maxShaders :int = 0;
		protected var m_currShader :int = -1;
		
		// shader data
		protected var m_shaderProgram      :Vector.<Program3D>         = null;
		protected var m_shaderVtxOpcodes   :Vector.<String>            = null;
		protected var m_shaderPxlOpcodes   :Vector.<String>            = null;
		protected var m_shaderVtxAssembler :Vector.<AGALMiniAssembler> = null;
		protected var m_shaderPxlAssembler :Vector.<AGALMiniAssembler> = null;
		protected var m_shaderVtxConst     :Vector.<Vector.<Number>>   = null;
		protected var m_shaderPxlConst     :Vector.<Vector.<Number>>   = null;
		
		// vertex buffer counters
		protected var m_numVtxBufs       :int = 0;
		protected var m_maxVtxBufs       :int = 0;
		protected var m_currVtxBuf       :int = -1;
		protected var m_vtxBufPrevNumFmt :int = 0;
		
		// vertex buffer data
		protected var m_vtxBufBuffer     :Vector.<VertexBuffer3D>  = null;
		protected var m_vtxBufIsStatic   :Vector.<Boolean>         = null;
		protected var m_vtxBufNumData    :Vector.<int>             = null;
		protected var m_vtxBufDataPerVtx :Vector.<int>             = null;
		protected var m_vtxBufNumVtx     :Vector.<int>             = null;
		protected var m_vtxBufVertices   :Vector.<Vector.<Number>> = null;
		protected var m_vtxBufNumFormat  :Vector.<int>             = null;
		protected var m_vtxBufFmtOffsets :Vector.<Vector.<int>>    = null;
		protected var m_vtxBufFmtTypes   :Vector.<Vector.<String>> = null;
		
		// index buffer counters
		protected var m_numIdxBufs :int = 0;
		protected var m_maxIdxBufs :int = 0;
		
		// index buffer data
		protected var m_idxBufBuffer   :Vector.<IndexBuffer3D> = null;
		protected var m_idxBufIsStatic :Vector.<Boolean>       = null;
		protected var m_idxBufNumIdx   :Vector.<int>           = null;
		protected var m_idxBufIndices  :Vector.<Vector.<uint>> = null;

		// texture counters
		protected var m_numTextures :int          = 0;
		protected var m_maxTextures :int          = 0;
		protected var m_currTexture :Vector.<int> = null;
		
		// texture data
		protected var m_texTexture        :Vector.<Texture>    = null;
		protected var m_texIsRenderTarget :Vector.<Boolean>    = null;
		protected var m_texBaseWidth      :Vector.<int>        = null;
		protected var m_texBaseHeight     :Vector.<int>        = null;
		protected var m_texPO2Width       :Vector.<int>        = null;
		protected var m_texPO2Height      :Vector.<int>        = null;
		protected var m_texBitmapData     :Vector.<BitmapData> = null;
		
		// view counters
		protected var m_numViews :int = 0;
		protected var m_maxViews :int = 0;

		// view data
		protected var m_viewTexIdx  :Vector.<int>              = null;
		protected var m_viewPosX    :Vector.<Number>           = null;
		protected var m_viewPosY    :Vector.<Number>           = null;
		protected var m_viewWidth   :Vector.<Number>           = null;
		protected var m_viewHeight  :Vector.<Number>           = null;
		protected var m_viewColor   :Vector.<Vector.<Number>>  = null;
		protected var m_viewVisible :Vector.<Boolean>          = null;
		protected var m_viewRender  :Boolean                   = true;
		
		// sound fx counters
		protected var m_numSounds :int = 0;
		protected var m_maxSounds :int = 0;
		
		// sound fx data
		//@@@

		// music counters
		protected var m_numMp3s :int = 0;
		protected var m_maxMp3s :int = 0;
		
		// music data
		//@@@

		// touch input data
		protected var m_maxTouches  :int              = 0;
		protected var m_touchX      :Vector.<int>     = null;
		protected var m_touchY      :Vector.<int>     = null;
		protected var m_touching    :Vector.<Boolean> = null;
		protected var m_wasTouching :Vector.<Boolean> = null;
		protected var m_touchActive :Vector.<Boolean> = null;
		
		// raw touch input data
		protected var m_rawTouchX        :Vector.<Number>  = null;
		protected var m_rawTouchY        :Vector.<Number>  = null;
		protected var m_rawTouching      :Vector.<Boolean> = null;
		protected var m_rawTouchActive   :Vector.<Boolean> = null;
		protected var m_rawTouchSysId    :Vector.<int>     = null;
		protected var m_rawTouchAppId    :Vector.<uint>    = null;
		protected var m_rawTouchAppIdCnt :uint             = 0;
	
		// touch scale factors
		protected var m_touchScaleX :Number = 0;
		protected var m_touchScaleY :Number = 0;
		
		// fps tracking data
		protected var m_fpsTex      :int     = -1;
		protected var m_fpsView     :int     = -1;
		protected var m_trackFps    :Boolean = false;
		protected var m_fpsNextTick :int     = 0;
		protected var m_fps         :int     = 0;
		protected var m_ups         :int     = 0;
		
		// memory tracking data
		protected var m_memTex      :int     = -1;
		protected var m_memView     :int     = -1;
		protected var m_trackMem    :Boolean = false;
		protected var m_memNextTick :int     = 0;
		
		// misc. constants
		protected static const ANTIALIAS_NONE :int = 0;
		protected static const ANTIALIAS_LOW  :int = 1;
		protected static const ANTIALIAS_HIGH :int = 2;
		protected static const ANTIALIAS_MAX  :int = 3;
		
		protected static const BLEND_NONE     :int = 0;
		protected static const BLEND_ALPHA    :int = 1;
		protected static const BLEND_ADDITIVE :int = 2;
		protected static const BLEND_MULTIPLY :int = 3;
		protected static const BLEND_SCREEN   :int = 4;
		
		public static const ORIENT_UNDEF     :int = 0;
		public static const ORIENT_LANDSCAPE :int = 1;
		public static const ORIENT_PORTRAIT  :int = 2;
		
		public static const OSFLAG_UNDEF   :int = 0;
		public static const OSFLAG_ANDROID :int = 1;
		public static const OSFLAG_IOS     :int = 2;
		public static const OSFLAG_MACOSX  :int = 3;
		public static const OSFLAG_WINDOWS :int = 4;
		public static const OSFLAG_BROWSER :int = 99;
		
		protected static const QUALITY_LOW    :int = 0;
		protected static const QUALITY_MEDIUM :int = 1;
		protected static const QUALITY_HIGH   :int = 2;
		protected static const QUALITY_BEST   :int = 3;
		
		protected static const AS3_TEXTURE_STAGES :int = 8;
		protected static const MAX_FRAME_SKIP     :int = 4;
		
		protected static const ERROR_BUFFER_NOT_CONFIGURED :int = 3698;
		protected static const ERROR_OBJECT_WAS_DISPOSED   :int = 3694;
		
		// getters
		public function get goingNative() :Boolean { return(m_goingNative);  }
		
		// setters
		public function set goingNative(val :Boolean) :void { m_goingNative  = val; }
		
		// default constructor
		public function WBEngine(sprite         :Sprite,
								 messenger      :WBMessenger,
								 osFlag         :int,
								 renderWhenIdle :Boolean,
								 launchImg      :Bitmap,
 								 appTitle       :String,
								 longestSide    :int,
								 orientation    :int,
								 baseAspect     :Number,
								 extAspect      :Number,
								 bkgColor       :uint,
								 maxShaders     :int,
								 maxBuffers     :int,
								 maxTextures    :int,
								 maxViews       :int,
								 maxSounds      :int,
								 maxMp3s        :int,
								 maxTouches     :int) :void
		{
			// copy opbjects
			m_sprite    = sprite;
			m_stage     = sprite.stage;
			m_messenger = messenger;
			m_launchImg = launchImg;
			
			// copy metadata from messenger
			m_swfWidth     = messenger.m_swfWidth;
			m_swfHeight    = messenger.m_swfHeight;
			m_swfFrameRate = messenger.m_swfFrameRate;
			
			// compute adjusted metadata values
			m_swfWidth2  = messenger.m_swfWidth  / 2;
			m_swfHeight2 = messenger.m_swfHeight / 2;
			
			// copy app data
			m_appTitle       = appTitle;
			m_osFlag         = osFlag;
			m_renderWhenIdle = renderWhenIdle;
			m_longestSide    = roundToEven(longestSide) as int;
			m_orientation    = orientation;
			m_baseAspect     = baseAspect;
			m_extAspect      = extAspect;
			m_frameRate      = m_swfFrameRate;
			m_frameDelay     = (m_swfFrameRate > 1) ? (1000 / m_swfFrameRate) : 1000;
			m_bkgColor       = bkgColor;
			
			// set object maximums
			m_maxShaders  = maxShaders  + 2; // +1 for launch image, +1 for views
			m_maxVtxBufs  = maxBuffers  + 2; // +1 for launch image, +1 for views
			m_maxIdxBufs  = maxBuffers  + 2; // +1 for launch image, +1 for views
			m_maxTextures = maxTextures;
			m_maxViews    = maxViews;
			m_maxSounds   = maxSounds;
			m_maxMp3s     = maxMp3s;
			m_maxTouches  = Multitouch.supportsTouchEvents ? maxTouches : 1;
			
			// init bare-minimum graphics component
			preInitGraphics();
		}
	
		// appAndroidBackKey() -- user has pushed Android back key **time-critical
		protected function appAndroidBackKey() :Boolean
		{
			// override this function to handle Android back key press
			// return(true) if the event was captured
			// return(false) to pass back to the system (i.e., hide app)
			return(false);
		}

		// appExit() -- perform cleanup specific to app (may or may not be called by os)
		protected function appExit() :void
		{
			// override this function to perform app cleanup
		}
		
		// appInit() -- perform initialization specific to app
		protected function appInit() :void
		{
			// override this function to perform app initialization
		}

		// appKeyDown() -- user has pushed a keyboard key **time-critical
		protected function appKeyDown(e :KeyboardEvent) :void
		{
			// override this function to process key presses
		}

		// appKeyUp() -- user has released a keyboard key **time-critical
		protected function appKeyUp(e :KeyboardEvent) :void
		{
			// override this function to process key releases
		}

		// appPause() -- handle loss of focus specific to app
		protected function appPause() :void
		{
			// override this function to handle loss-of-focus events
		}
		
		// appRender() -- handle rendering specific to app **time-critical
		protected function appRender() :void
		{
			// override this function to perform app-specific rendering
		}
		
		// appResize() -- handle window resize specific to app
		protected function appResize() :void
		{
			// override this function to handle window-resize events
		}
		
		// appResume() -- handle return of focus specific to app
		protected function appResume() :void
		{
			// override this function to handle return-of-focus events
		}
		
		// appUpdate() -- per-frame update specific to app **time-critical
		protected function appUpdate() :void
		{
			// override this function to handle per-frame app updates
		}
		
		// calculateRenderSizes() -- calculate data needed for proper rendering
		protected function calculateRenderSizes() :void
		{
			// check orientation (if undefined, use landscape)
			if(m_orientation == ORIENT_PORTRAIT)
			{
				// compute base size (portrait)
				m_baseHeight  = m_longestSide as Number;
				m_baseWidth   = roundToEven(m_baseHeight / m_baseAspect);
				
				// compute extended size
				m_extWidth  = m_baseWidth;
				m_extHeight = roundToEven(m_extWidth * m_extAspect);

				// compute extended origin
				m_extX = 0;
				m_extY = (m_baseHeight - m_extHeight) / 2;
				
				// compute auxiliary sizes
				m_auxWidth  = m_baseWidth;
				m_auxHeight = -m_extY;
			}
			else
			{
				// compute base size (landscape)
				m_baseWidth  = m_longestSide as Number;
				m_baseHeight = roundToEven(m_baseWidth / m_baseAspect);
				
				// compute extended size
				m_extHeight = m_baseHeight;
				m_extWidth  = roundToEven(m_extHeight * m_extAspect);

				// compute extended origin
				m_extX = (m_baseWidth - m_extWidth) / 2;
				m_extY = 0;
				
				// compute auxiliary sizes
				m_auxWidth  = -m_extX;
				m_auxHeight = m_baseHeight;
			}
			
			// output target sizes
			trace("Render sizes: base = " + m_baseWidth + "x" + m_baseHeight +
							    " ext = " + m_extWidth  + "x" + m_extHeight  +
						 	    " aux = " + m_auxWidth  + "x" + m_auxHeight);
			
			// compute half-sizes
			m_baseWidth2  = m_baseWidth  / 2;
			m_baseHeight2 = m_baseHeight / 2;
			
			// remainder is handled by resize
			handleResize();
		}
		
		// computeFramesElapsed() -- compute number of frame renders elapsed since last render **time-critical
		protected function computeFramesElapsed() :int
		{
			// get current tick
			var currentTick :int = getTickCount();

			// compute frames elapsed
			var framesElapsed :int = ((currentTick - m_frameSkipTick) / m_frameDelay);
			
			// check overflow
			if(framesElapsed > MAX_FRAME_SKIP)
			{
				// clip value
				framesElapsed = MAX_FRAME_SKIP;
				
				// set new tick count
				m_frameSkipTick = currentTick;
			}
			else
			{
				// adjust tick count
				m_frameSkipTick += (framesElapsed * m_frameDelay);
			}
			
			// return frames elapsed
			return(framesElapsed);
		}
		
		// debugRectToBitmapData() -- helper function draw rectangle to bitmap data
		protected function debugRectToBitmapData(bmpData :BitmapData,
												 x       :int,
												 y       :int,
												 width   :int,
												 height  :int,
												 color   :uint) :void
		{
			// create rectangle
			var rect :Rectangle = new Rectangle (x, y, width, height);
			
			// draw rect to bitmap data
			bmpData.fillRect(rect, color);
		}
		
		// debugTextToBitmapData() -- add simple text to bitmap data **SLOW!! preface with ~ to right/bottom-justify
		protected function debugTextToBitmapData(bmpData :BitmapData,
												 text    :String,
												 x       :int,
												 y       :int,
												 scale   :int  = 1,
												 color   :uint = 0xFFFFFFFF) :void
		{
			// check for right-justify
			if(text.charAt(0) == "~")
			{
				// adjust text & convert to uppercase
				text = text.substring(1).toUpperCase();
				
				// adjust position
				x -= (text.length * scale * 6) - scale;
				y -= scale * 5;
			}
			else
			{
				// convert text to uppercase
				text = text.toUpperCase();
			}
			
			// output string
			var output :String;
			
			// process each character
			for(var c: int = 0; c < text.length; c++)
			{
				// check character
				switch(text.charAt(c))
				{
					case(" "): output = "     " +
										"     " +
										"     " +
										"     " +
										"     " ;  break;
					case("!"): output = "  #  " +
										"  #  " +
										"  #  " +
										"     " +
										"  #  " ;  break;
					case("\""):output = " # # " +
										" # # " +
										"     " +
										"     " +
										"     " ;  break;
					case("#"): output = " # # " +
										"#####" +
										" # # " +
										"#####" +
										" # # " ;  break;
					case("$"): output = " ####" +
										"# #  " +
										" ### " +
										"  # #" +
										"#### " ;  break;
					case("%"): output = "##  #" +
										"## # " +
										"  #  " +
										" # ##" +
										"#  ##" ;  break;
					case("&"): output = " ### " +
										"#    " +
										" ##  " +
										"#  # " +
										" ## #" ;  break;
					case("'"): output = "  #  " +
										"  #  " +
										"     " +
										"     " +
										"     " ;  break;
					case("("): output = "  #  " +
										" #   " +
										" #   " +
										" #   " +
										"  #  " ;  break;
					case(")"): output = "  #  " +
										"   # " +
										"   # " +
										"   # " +
										"  #  " ;  break;
					case("*"): output = " # # " +
										"  #  " +
										" # # " +
										"     " +
										"     " ;  break;
					case("+"): output = "     " +
										"  #  " +
										" ### " +
										"  #  " +
										"     " ;  break;
					case(","): output = "     " +
										"     " +
										"     " +
										"  #  " +
										" #   " ;  break;
					case("-"): output = "     " +
										"     " +
										" ### " +
										"     " +
										"     " ;  break;
					case("."): output = "     " +
										"     " +
										"     " +
										"     " +
										"  #  " ;  break;
					case("/"): output = "    #" +
										"   # " +
										"  #  " +
										" #   " +
										"#    " ;  break;
					case("0"): output = " ### " +
										"#   #" +
										"# # #" +
										"#   #" +
										" ### " ;  break;
					case("1"): output = "  #  " +
										" ##  " +
										"  #  " +
										"  #  " +
										" ### " ;  break;
					case("2"): output = " ### " +
										"#   #" +
										"  ## " +
										" #   " +
										"#####" ;  break;
					case("3"): output = "#### " +
										"    #" +
										" ### " +
										"    #" +
										"#### " ;  break;
					case("4"): output = "  ## " +
										" # # " +
										"#  # " +
										"#####" +
										"   # " ;  break;
					case("5"): output = "#####" +
										"#    " +
										"#### " +
										"    #" +
										"#### " ;  break;
					case("6"): output = " ### " +
										"#    " +
										"#### " +
										"#   #" +
										" ### " ;  break;
					case("7"): output = "#####" +
										"    #" +
										"   # " +
										"  #  " +
										"  #  " ;  break;
					case("8"): output = " ### " +
										"#   #" +
										" ### " +
										"#   #" +
										" ### " ;  break;
					case("9"): output = " ### " +
										"#   #" +
										" ####" +
										"    #" +
										" ### " ;  break;
					case(":"): output = "     " +
										"  #  " +
										"     " +
										"  #  " +
										"     " ;  break;
					case(";"): output = "     " +
										"  #  " +
										"     " +
										"  #  " +
										" #   " ;  break;
					case("<"): output = "   # " +
										"  #  " +
										" #   " +
										"  #  " +
										"   # " ;  break;
					case("="): output = "     " +
										" ### " +
										"     " +
										" ### " +
										"     " ;  break;
					case(">"): output = " #   " +
										"  #  " +
										"   # " +
										"  #  " +
										" #   " ;  break;
					case("?"): output = " ### " +
										"#   #" +
										"  ## " +
										"     " +
										"  #  " ;  break;
					case("@"): output = " ### " +
										"#   #" +
										"# ## " +
										"#    " +
										" ###  " ;  break;
					case("A"): output = " ### " +
										"#   #" +
										"#####" +
										"#   #" +
										"#   #" ;  break;
					case("B"): output = "#### " +
										"#   #" +
										"#### " +
										"#   #" +
										"#### " ;  break;
					case("C"): output = " ### " +
										"#   #" +
										"#    " +
										"#   #" +
										" ### " ;  break;
					case("D"): output = "###  " +
										"#  # " +
										"#   #" +
										"#  # " +
										"###  " ;  break;
					case("E"): output = "#####" +
										"#    " +
										"#### " +
										"#    " +
										"#####" ;  break;
					case("F"): output = "#####" +
										"#    " +
										"#### " +
										"#    " +
										"#    " ;  break;
					case("G"): output = " ### " +
										"#    " +
										"# ###" +
										"#   #" +
										" ### " ;  break;
					case("H"): output = "#   #" +
										"#   #" +
										"#####" +
										"#   #" +
										"#   #" ;  break;
					case("I"): output = " ### " +
										"  #  " +
										"  #  " +
										"  #  " +
										" ### " ;  break;
					case("J"): output = "    #" +
										"    #" +
										"    #" +
										"#   #" +
										" ### " ;  break;
					case("K"): output = "#   #" +
										"#  # " +
										"###  " +
										"#  # " +
										"#   #" ;  break;
					case("L"): output = "#    " +
										"#    " +
										"#    " +
										"#    " +
										"#####" ;  break;
					case("M"): output = "#   #" +
										"## ##" +
										"# # #" +
										"#   #" +
										"#   #" ;  break;
					case("N"): output = "#   #" +
										"##  #" +
										"# # #" +
										"#  ##" +
										"#   #" ;  break;
					case("O"): output = " ### " +
										"#   #" +
										"#   #" +
										"#   #" +
										" ### " ;  break;
					case("P"): output = "#### " +
										"#   #" +
										"#### " +
										"#    " +
										"#    " ;  break;
					case("Q"): output = " ### " +
										"#   #" +
										"#   #" +
										"#  # " +
										" ## #" ;  break;
					case("R"): output = "#### " +
										"#   #" +
										"#### " +
										"#   #" +
										"#   #" ;  break;
					case("S"): output = " ####" +
										"#    " +
										" ### " +
										"    #" +
										"#### " ;  break;
					case("T"): output = "#####" +
										"  #  " +
										"  #  " +
										"  #  " +
										"  #  " ;  break;
					case("U"): output = "#   #" +
										"#   #" +
										"#   #" +
										"#   #" +
										" ### " ;  break;
					case("V"): output = "#   #" +
										"#   #" +
										"#   #" +
										" # # " +
										"  #  " ;  break;
					case("W"): output = "#   #" +
										"#   #" +
										"# # #" +
										"# # #" +
										" # # " ;  break;
					case("X"): output = "#   #" +
										" # # " +
										"  #  " +
										" # # " +
										"#   #" ;  break;
					case("Y"): output = "#   #" +
										" # # " +
										"  #  " +
										"  #  " +
										"  #  " ;  break;
					case("Z"): output = "#####" +
										"   # " +
										"  #  " +
										" #   " +
										"#####" ;  break;
					case("["): output = "  ## " +
										"  #  " +
										"  #  " +
										"  #  " +
										"  ## " ;  break;
					case("\\"):output = "#    " +
										" #   " +
										"  #  " +
										"   # " +
										"    #" ;  break;
					case("]"): output = " ##  " +
										"  #  " +
										"  #  " +
										"  #  " +
										" ##  " ;  break;
					case("^"): output = "  #  " +
										" # # " +
										"     " +
										"     " +
										"     " ;  break;
					case("_"): output = "     " +
										"     " +
										"     " +
										"     " +
										"#####" ;  break;
					default:   output = "#####" +
										"#   #" +
										"#   #" +
										"#   #" +
										"#####" ; break;
				}
				
				// set starting y
				var y1 :int = y; 
				
				// process each line
				for(var cy :int = 0; cy < 5; cy++)
				{
					// set starting x
					var x1 :int = x;
					
					// process each pixel
					for(var cx :int = 0; cx < 5; cx++)
					{
						// output scaled pixel if indicated
						if(output.charAt(cx + (cy * 5)) != " ")
							for(var ny :int = 0; ny < scale; ny++)
								for(var nx :int = 0; nx < scale; nx++)
									bmpData.setPixel32(x1 + nx, y1+ ny, color);
										
						
						// increment x1
						x1 += scale;
					}
					
					// incdrement y1
					y1 += scale;
				}
						
				// increment x
				x += scale * 6;
			}
		}

		// deleteSharedData() -- erase global shared object (permanently!)
		public function deleteSharedData() :void
		{
			// clear the data (if avaialble)
			if(m_shared)
				m_shared.clear();
		}
		
		// disableBackfaceCull() -- disable backface culling **time-critical
		protected function disableBackfaceCull() :void
		{
			// enable with false
			enableBackfaceCull(false);
		}
		
		// disableDepthTest() -- disable depth testing **time-critical
		protected function disableDepthTest() :void
		{
			// enable with false
			enableDepthTest(false);
		}
		
		// disableFrontfaceCull() -- disable frontface culling **time-critical 
		protected function disableFrontfaceCull() :void
		{
			// enable with false
			enableFrontfaceCull(false);
		}
		
		// disableGraphicsErrors() -- disable checking for graphics errors
		protected function disableGraphicsErrors() :void
		{
			// enable with false
			enableGraphicsErrors(false);
		}
		
		// disableStencilTest() -- disable stencil buffer testing **time-critical
		protected function disableStencilTest() :void
		{
			// enable with false
			enableStencilTest(false);
		}
		
		// disableViewRender() -- disable rendering of views (for apps that do their own rendering)
		protected function disableViewRender() :void
		{
			// clear flag
			m_viewRender = false;
		}

		// enableBackfaceCull() -- enable/disable backface culling **time-critical
		protected function enableBackfaceCull(flag :Boolean = true) :void
		{
			// NOTE: changes must be duplicated at enableFrontFaceCull()
			
			// save flag
			m_backfaceCull = flag;
			
			// verify context3D
			if(!m_context3DReady)
				return;
			
			// culling flag
			var triangleFace :String;
			
			// check backface cull
			if(m_backfaceCull)
			{
				// check frontface cull
				if(m_frontfaceCull)
					triangleFace = Context3DTriangleFace.FRONT_AND_BACK;
				else
					triangleFace = Context3DTriangleFace.BACK;
			}
			else
			{
				// check frontface cull
				if(m_frontfaceCull)
					triangleFace = Context3DTriangleFace.FRONT;
				else
					triangleFace = Context3DTriangleFace.NONE;
			}
			
			// apply culling flag
			m_context3D.setCulling(triangleFace);
		}
		
		// enableDepthTest() -- enable/disable depth testing **time-critical
		protected function enableDepthTest(flag :Boolean = true) :void
		{
			// save flag
			m_depthTest = flag;
			
			// set depth-test mode
			if(m_context3DReady)
				m_context3D.setDepthTest(flag,
										 flag ? Context3DCompareMode.LESS
										 	  : Context3DCompareMode.ALWAYS);
		}
		
		// enableFrontfaceCull() -- enable/disable frontface culling **time-critical
		protected function enableFrontfaceCull(flag :Boolean = true) :void
		{
			// NOTE: changes must be duplicated at enableFrontFaceCull()
			
			// save flag
			m_frontfaceCull = flag;
			
			// verify context3D
			if(!m_context3DReady)
				return;
			
			// culling flag
			var triangleFace :String;
			
			// check backface cull
			if(m_backfaceCull)
			{
				// check frontface cull
				if(m_frontfaceCull)
					triangleFace = Context3DTriangleFace.FRONT_AND_BACK;
				else
					triangleFace = Context3DTriangleFace.BACK;
			}
			else
			{
				// check frontface cull
				if(m_frontfaceCull)
					triangleFace = Context3DTriangleFace.FRONT;
				else
					triangleFace = Context3DTriangleFace.NONE;
			}
			
			// apply culling flag
			m_context3D.setCulling(triangleFace);
		}

		// enableGraphicsErrors() -- enable/disable graphics error checking
		protected function enableGraphicsErrors(flag :Boolean = true) :void
		{
			// save flag
			m_graphicsErrors = flag;
			
			// enable as needed
			if(m_context3DReady)
				m_context3D.enableErrorChecking = flag;
		}

		// enableStencilTest() -- enable/disable stencil buffer testing **time-critical
		protected function enableStencilTest(flag :Boolean = true) :void
		{
			// save flag
			m_stencilTest = flag;
			
			// enable/disable as needed
			if(m_context3DReady)
				m_context3D.setStencilActions(flag ? Context3DTriangleFace.FRONT_AND_BACK
												   : Context3DTriangleFace.NONE);
		}

		// enableViewRender() -- enable rendering of views (for apps that do their own rendering)
		protected function enableViewRender() :void
		{
			// set flag
			m_viewRender = true;
		}

		// get AvailableTouchIndex() -- retrieve any available multitouch index **time-critical
		protected function getAvailableTouchIndex(e :TouchEvent) :int
		{
			// reset index
			var idx :int = 0;
			
			// search for available touch
			while(idx < m_maxTouches)
			{
				// use any non-touching slot
				if(!m_rawTouching[idx])
				{
					// store id values
					m_rawTouchSysId[idx] = e.touchPointID;
					m_rawTouchAppId[idx] = m_rawTouchAppIdCnt++;
					
					// return index
					return(idx);
				}
				
				// update index
				idx++;
			}
			
			// sorry, no-can-do
			return(-1);
		}

		// getMatchingTouchIndex() -- retrieve matching touch index, or create new if needed **time-critical
		protected function getMatchingTouchIndex(e :TouchEvent) :int
		{
			// reset index
			var idx :int = 0;
			
			// look for matching id
			while(idx < m_maxTouches)
			{
				// check for match
				if(m_rawTouchSysId[idx] == e.touchPointID)
					return(idx);
				
				// update index
				idx++;
			}
			
			// if not found, get a new one
			return(getAvailableTouchIndex(e));
		}
		
		// getStage() -- retrieve primary stage object
		public function getStage() :Stage
		{
			// return object
			return(m_stage);
		}
		
		// getTickCount() -- get system millisecond timer
		protected function getTickCount() :int
		{
			// return timer value
			return(getTimer());
		}

		// getTitle() -- retrieve application title string
		public function getTitle() :String
		{
			// return object
			return(m_appTitle);
		}
		
		// handleResize() -- calculate data needed for proper rendering
		protected function handleResize() :void
		{
			// verify stage
			if(!m_stage)
				return;

			// get stage size
			m_stageWidth  = roundToEven(m_stage.stageWidth);
			m_stageHeight = roundToEven(m_stage.stageHeight);
			
			// compute stage origin
			m_stageX = (m_swfWidth  - m_stageWidth ) / 2;
			m_stageY = (m_swfHeight - m_stageHeight) / 2;
			
			// check orientation (if undefined, use landscape)
			if(m_orientation == ORIENT_PORTRAIT)
			{
				// compute new aspect ratio
				m_stageAspect = m_stageHeight / m_stageWidth;
				
				// check aspect ratio
				if(m_stageAspect < m_baseAspect)
				{
					// set edges
					m_leftEdge   = 0;
					m_rightEdge  = m_baseWidth;
					m_topEdge    = 0;
					m_bottomEdge = m_baseHeight;

					// compute viewport width
					m_viewportWidth = roundToEven(m_stageHeight / m_baseAspect);
					
					// compute viewport (stage too wide)
					m_viewportX      = m_stageX + ((m_stageWidth - m_viewportWidth) / 2);
					m_viewportY      = m_stageY;
					m_viewportHeight = m_stageHeight;
					
					// compute launch image height
					m_boundsHeight = roundToEven(m_viewportWidth * m_extAspect);
					
					// set launch image bounds
					m_boundsX     = m_viewportX;
					m_boundsY     = m_viewportY + ((m_viewportHeight - m_boundsHeight) / 2);
					m_boundsWidth = m_viewportWidth;
				}
				else if (m_stageAspect > m_extAspect)
				{
					// set edges
					m_leftEdge   = 0;
					m_rightEdge  = m_baseWidth;
					m_topEdge    = (m_baseHeight - m_extHeight) / 2;
					m_bottomEdge = m_baseHeight - m_topEdge;

					// compute viewport height
					m_viewportHeight = roundToEven(m_stageWidth * m_extAspect);
					
					// compute viewport (stage too tall)
					m_viewportX      = m_stageX;
					m_viewportY      = m_stageY + ((m_stageHeight - m_viewportHeight) / 2);
					m_viewportWidth  = m_stageWidth;
					
					// set launch image bounds
					m_boundsX      = m_viewportX;
					m_boundsY      = m_viewportY;
					m_boundsWidth  = m_viewportWidth;
					m_boundsHeight = m_viewportHeight;
				}
				else
				{
					// compute working height
					var workHeight :Number = roundToEven(m_baseWidth * m_stageAspect);
					
					// set edges
					m_leftEdge   = 0;
					m_rightEdge  = m_baseWidth;
					m_topEdge    = (m_baseHeight - workHeight) / 2;
					m_bottomEdge = m_baseHeight - m_topEdge;
					
					// set viewport (full stage)
					m_viewportX      = m_stageX;
					m_viewportY      = m_stageY;
					m_viewportWidth  = m_stageWidth;
					m_viewportHeight = m_stageHeight;
					
					// compute launch image height
					m_boundsHeight = roundToEven(m_viewportWidth * m_extAspect);
					
					// set launch image bounds
					m_boundsX     = m_viewportX;
					m_boundsY     = m_viewportY + ((m_viewportHeight - m_boundsHeight) / 2);
					m_boundsWidth = m_viewportWidth;
				}
			}
			else
			{
				// compute new aspect ratio
				m_stageAspect = m_stageWidth / m_stageHeight;
				
				// check aspect ratio
				if(m_stageAspect < m_baseAspect)
				{
					// set edges
					m_leftEdge   = 0;
					m_rightEdge  = m_baseWidth;
					m_topEdge    = 0;
					m_bottomEdge = m_baseHeight;
					
					// compute viewport height
					m_viewportHeight = roundToEven(m_stageWidth / m_baseAspect);
					
					// compute viewport (stage too tall)
					m_viewportX      = m_stageX;
					m_viewportY      = m_stageY + ((m_stageHeight - m_viewportHeight) / 2);
					m_viewportWidth  = m_stageWidth;
					
					// compute launch image width
					m_boundsWidth = roundToEven(m_viewportHeight * m_extAspect);
					
					// set launch image bounds
					m_boundsX      = m_viewportX + ((m_viewportWidth - m_boundsWidth) / 2);
					m_boundsY      = m_viewportY;
					m_boundsHeight = m_viewportHeight;
				}
				else if (m_stageAspect > m_extAspect)
				{
					// set edges
					m_leftEdge   = (m_baseWidth - m_extWidth) / 2;
					m_rightEdge  = m_baseWidth - m_leftEdge;
					m_topEdge    = 0;
					m_bottomEdge = m_baseHeight;
					
					// compute viewport width
					m_viewportWidth = roundToEven(m_stageHeight * m_extAspect);
					
					// compute viewport (stage too wide)
					m_viewportX      = m_stageX + ((m_stageWidth - m_viewportWidth) / 2);
					m_viewportY      = m_stageY;
					m_viewportHeight = m_stageHeight;
					
					// set launch image bounds
					m_boundsX      = m_viewportX;
					m_boundsY      = m_viewportY;
					m_boundsWidth  = m_viewportWidth;
					m_boundsHeight = m_viewportHeight;
				}
				else
				{
					// compute working width
					var workWidth :Number = roundToEven(m_baseHeight * m_stageAspect);
					
					// set edges
					m_leftEdge   = (m_baseWidth - workWidth) / 2;
					m_rightEdge  = m_baseWidth - m_leftEdge;
					m_topEdge    = 0;
					m_bottomEdge = m_baseHeight;
					
					// set viewport (full stage)
					m_viewportX      = m_stageX;
					m_viewportY      = m_stageY;
					m_viewportWidth  = m_stageWidth;
					m_viewportHeight = m_stageHeight;
					
					// compute launch image width
					m_boundsWidth = roundToEven(m_viewportHeight * m_extAspect);
					
					// set launch image bounds
					m_boundsX      = m_viewportX + ((m_viewportWidth - m_boundsWidth) / 2);
					m_boundsY      = m_viewportY;
					m_boundsHeight = m_viewportHeight;
				}
			}
			
			// compute visible size
			m_visibleWidth  = m_rightEdge  - m_leftEdge;
			m_visibleHeight = m_bottomEdge - m_topEdge;
			
			// compute view offsets
			m_viewOfsX = -(m_baseWidth  / m_visibleWidth);
			m_viewOfsY =  (m_baseHeight / m_visibleHeight);
			
			// compute view scale factors
			m_viewScaleX = (-2 * m_viewOfsX) / m_baseWidth;
			m_viewScaleY = (-2 * m_viewOfsY) / m_baseHeight;
			
			// compute touch scale values
			m_touchScaleX = m_visibleWidth  / m_viewportWidth;
			m_touchScaleY = m_visibleHeight / m_viewportHeight;
			
			// compute edges - 1
			m_rightEdge1  = m_rightEdge  - 1;
			m_bottomEdge1 = m_bottomEdge - 1;
		}
		
		// hideFpsDisplayView() -- hide the fps display view
		protected function hideFpsDisplayView() :void
		{
			// check flag
			if(m_trackFps)
			{
				// hide view
				viewSetInvisible(m_fpsView);
				
				// stop tracking
				m_trackFps = false;
			}
		}
		
		// hideLaunchImageView() -- hide the launch image view
		protected function hideLaunchImageView() :void
		{
			// hide if created
			if(m_launchImgView >= 0)
				viewSetInvisible(m_launchImgView);
		}
		
		// hideLaunchImage3D() -- hide the 3D-rendered version of the launch image
		protected function hideLaunchImage3D() :void
		{
			// make invisible
			m_launchImg3DVisible = false;
		}
		// hideMemoryDisplayView() -- hide the memory display view
		protected function hideMemoryDisplayView() :void
		{
			// check flag
			if(m_trackMem)
			{
				// hide view
				viewSetInvisible(m_memView);
				
				// stop tracking
				m_trackMem = false;
			}
		}
		
		// indexBufferAdd() -- add new index buffer object
		protected function indexBufferAdd(indices  :Vector.<uint>,
										  isStatic :Boolean = true) :int
		{
			// get next index buffer
			var idx :int = indexBufferGetNext();
			
			// stop at invalid index
			if(idx < 0)
				return(idx);
			
			// copy static flag
			m_idxBufIsStatic[idx] = isStatic;
			
			// set initial indices
			if(indices)
				indexBufferUpdateIndices(idx, indices);
			
			// return index
			return(idx);
		}
		
		// indexBufferGetNext() -- get next avaialble index buffer
		protected function indexBufferGetNext() :int
		{
			// check for overflow
			if(m_numIdxBufs >= m_maxIdxBufs)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.indexBufferGetNext(): " +
								"Maximum number of index buffers exceeded");
				
				// stop here
				return(-1);
			}
			
			// verify context3D
			if(!m_context3DReady)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.indexBufferGetNext(): " +
								"No render surface is available");
				
				// stop here
				return(-1);
			}
			
			// create arrays if needed
			if(!m_idxBufBuffer  ) m_idxBufBuffer   = new Vector.<IndexBuffer3D>(m_maxIdxBufs, true);
			if(!m_idxBufIsStatic) m_idxBufIsStatic = new Vector.<Boolean>      (m_maxIdxBufs, true);
			if(!m_idxBufNumIdx  ) m_idxBufNumIdx   = new Vector.<int>          (m_maxIdxBufs, true);
			if(!m_idxBufIndices ) m_idxBufIndices  = new Vector.<Vector.<uint>>(m_maxIdxBufs, true);
			
			// init index buffer data
			m_idxBufBuffer  [m_numIdxBufs] = null;
			m_idxBufIsStatic[m_numIdxBufs] = false;
			m_idxBufNumIdx  [m_numIdxBufs] = 0;
			m_idxBufIndices [m_numIdxBufs] = new Vector.<uint>;
			
			// return index & increment
			return(m_numIdxBufs++);
		}
		
		// indexBufferRender() -- render using this index buffer **time-critical
		protected function indexBufferRender(idx          :int,
											 firstIndex   :int = 0,
										 	 numTriangles :int = -1) :void
		{
			// draw triangles using selected index buffer
			m_context3D.drawTriangles(m_idxBufBuffer[idx],
									  firstIndex,
									  numTriangles);
		}
		
		// indexBufferUpdateIndices() -- set new indices for index buffer **time-critical
		protected function indexBufferUpdateIndices(idx    :int,
													values :Vector.<uint>,
													start  :int = 0) :void
		{
			// counters
			var n1 :int;
			var n2 :int = start;
			
			// copy each value
			for(n1 = 0; n1 < values.length; n1++)
				m_idxBufIndices[idx][n2++] = values[n1];
			
			// check for overflow (n2 == numIdx)
			if(n2 > m_idxBufNumIdx[idx])
			{
				// set new max
				m_idxBufNumIdx[idx] = n2;
				
				// re-create & upload buffer
				indexBufferUpload(idx, true);
			}
			else
			{
				// re-upload buffer
				indexBufferUpload(idx);
			}
		}

		// indexBufferUpload() -- upload index buffer to graphics card **time-critical
		protected function indexBufferUpload(idx      :int,
											 recreate :Boolean = false) :void
		{
			// verify context
			if(!m_context3DReady)
				return;
			
			// catch errors
			try
			{
				// re-create buffer if needed
				if(recreate) // || !m_idxBufBuffer[idx] <-- not necessary to check
					m_idxBufBuffer[idx] = m_context3D.createIndexBuffer(m_idxBufNumIdx  [idx],
																		m_idxBufIsStatic[idx] ? Context3DBufferUsage.STATIC_DRAW
											  												  : Context3DBufferUsage.DYNAMIC_DRAW);
				
				// upload index buffer
				m_idxBufBuffer[idx].uploadFromVector(m_idxBufIndices[idx],
													 0,
													 m_idxBufNumIdx[idx]);
			}
			catch(e: Error)
			{
				// check for loss of context
				if(e.errorID == ERROR_OBJECT_WAS_DISPOSED)
					m_context3DReady = false;
				else
					throw(e);
			}
		}
		
		// init() -- let's get this show on the road!
		public function init(deleteData :Boolean = false) :void
		{			
			// load persistent data
			loadSharedData();
			
			// delete data if requested (testing purposes only!)
			if(deleteData)
				deleteSharedData();
			
			// initialize components
			initGraphics();
			initInput();
			initMusic();
			initSound();
			
			// app init was moved to first update
			
			// initialize timers
			initTimers();
			
			// add basic event listeners
			m_stage.addEventListener(Event.ACTIVATE,   onActivate);			
			m_stage.addEventListener(Event.CLOSING,    onClosing);			
			m_stage.addEventListener(Event.DEACTIVATE, onDeactivate);			
			m_stage.addEventListener(Event.EXITING,    onExiting);			
			m_stage.addEventListener(Event.RESIZE,     onResize);

		}
		
		// initGraphics() -- initialize graphics component
		protected function initGraphics() :void
		{
			// verify stage
			if(!m_stage)
				return;

			// extract background color components
			m_bkgColorRed   = (((m_bkgColor >> 16) & 0xFF) as Number) / 255;
			m_bkgColorGreen = (((m_bkgColor >>  8) & 0xFF) as Number) / 255;
			m_bkgColorBlue  = (((m_bkgColor      ) & 0xFF) as Number) / 255;
			
			// create current texture array
			m_currTexture = new Vector.<int>(AS3_TEXTURE_STAGES, true);
			
			// reset current texture array
			for(var c :int = 0; c < AS3_TEXTURE_STAGES; c++)
				m_currTexture[c] = -1;
			
			// get primary stage3D object
			m_stage3D = m_stage.stage3Ds[0];
			
			// verify object
			if(!m_stage3D)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.initGraphics(): " + 
					"No compatible rendering surfaces were found");
				
				// stop here
				return;
			}
			
			// listen for context create
			m_stage3D.addEventListener(Event.CONTEXT3D_CREATE,
									   onContext3DCreate);

			// request context
			requestContext3D();
		}
		
		// initInput() -- initialize input component
		protected function initInput() :void
		{
			// verify stage
			if(!m_stage)
				return;
		
			// register keyboard capture functions
			m_stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			m_stage.addEventListener(KeyboardEvent.KEY_UP,   onKeyUp);
			
			// create touch data arrays
			m_touchX      = new Vector.<int>    (m_maxTouches, true);
			m_touchY      = new Vector.<int>    (m_maxTouches, true);
			m_touching    = new Vector.<Boolean>(m_maxTouches, true);
			m_wasTouching = new Vector.<Boolean>(m_maxTouches, true);
			m_touchActive = new Vector.<Boolean>(m_maxTouches, true);
			
			// create raw touch data arrays
			m_rawTouchX      = new Vector.<Number> (m_maxTouches, true);
			m_rawTouchY      = new Vector.<Number> (m_maxTouches, true);
			m_rawTouching    = new Vector.<Boolean>(m_maxTouches, true);
			m_rawTouchActive = new Vector.<Boolean>(m_maxTouches, true);
			m_rawTouchSysId  = new Vector.<int>    (m_maxTouches, true);
			m_rawTouchAppId  = new Vector.<uint>   (m_maxTouches, true);

			// init touch data
			for(var c :int = 0; c < m_maxTouches; c++)
			{
				// init all values
				m_touchX        [c] = 0;
				m_touchY        [c] = 0;
				m_touching      [c] = false;
				m_wasTouching   [c] = false;
				m_touchActive   [c] = false;
				m_rawTouchX     [c] = 0;
				m_rawTouchY     [c] = 0;
				m_rawTouching   [c] = false;
				m_rawTouchActive[c] = false;
				m_rawTouchSysId [c] = 0;
				m_rawTouchAppId [c] = 0;
			}
			
			// check touch count
			if(m_maxTouches == 1)
			{
				// disable touch events
				Multitouch.inputMode = MultitouchInputMode.NONE;
				
				// register mouse events
				m_stage.addEventListener(MouseEvent.MOUSE_DOWN,  onMouseDown);
				m_stage.addEventListener(Event     .MOUSE_LEAVE, onMouseLeave);
				m_stage.addEventListener(MouseEvent.MOUSE_MOVE,  onMouseMove);
				m_stage.addEventListener(MouseEvent.MOUSE_UP,    onMouseUp);
			}
			else
			{
				// disable mouse events
				Multitouch.mapTouchToMouse = false;
				
				// disable gestures (we want raw points only)
				Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
				
				// register touch events
				m_stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
				m_stage.addEventListener(TouchEvent.TOUCH_END,   onTouchEnd);
				m_stage.addEventListener(TouchEvent.TOUCH_MOVE,  onTouchMove);
			}
			
			// disable child events
			m_stage.mouseChildren = false;
			m_stage.tabChildren   = false;
		}
		
		// initMusic() -- initialize music component
		protected function initMusic() :void
		{
			trace("initMusic");
		}
		
		// initSound() -- initialize sound component
		protected function initSound() :void
		{
			trace("initSound");
		}
		
		// initTimers() -- initialize timer objects
		protected function initTimers() :void
		{
			// create timers
			m_firstUpdateTimer = new Timer(m_frameDelay, 1); // 1x, based on frame rate
			m_frameRateTimer   = new Timer(m_frameDelay, 0); // frames/sec (infinite)
			
			// add timer event listeners
			m_firstUpdateTimer.addEventListener(TimerEvent.TIMER, onFirstUpdateTimer);
			m_frameRateTimer  .addEventListener(TimerEvent.TIMER, onFrameRateTimer);
			
			// start first-update timer
			m_firstUpdateTimer.start();
		}
		
		// loadSharedData() -- load global shared object (for persistent data)
		protected function loadSharedData() :void
		{
			// load the object
			m_shared = SharedObject.getLocal("usr_data");
		}
		
		// messageBox() -- display modal message box
		public function messageBox(message :String) :void
		{
			// request from caller via messenger
			if(m_messenger)
				m_messenger.send("messageBox", m_appTitle, message);
		}
		
		// musicPause() -- pause all music output (suitable for future resume) **time-critical
		protected function musicPause() :void
		{
			trace("musicPause");
		}
		
		// musicResume() -- resume previously paused music output **time-critical
		protected function musicResume() :void
		{
			trace("musicResume");
		}
		
		// musicStop() -- stop all music output (cannot be resumed) **time-critical
		protected function musicStop() :void
		{
			trace("musicStop");
		}
		
		// nextGreaterPO2() -- get first power-of-two value greater than the given number
		protected function nextGreaterPO2(val :Number) :int
		{
			// set starting value
			var po2 :int = 1;
			
			// double until greater or equal
			while(po2 < val)
				po2 <<= 1;
			
			// return new value
			return(po2);
		}

		// onActivate() -- app window is activating
		protected function onActivate(e :Event) :void
		{
			// check init
			if(!m_init)
				return;
			
			// regain focus
			onFocusReturned();

			// resume render if needed
			if(!m_renderWhenIdle)
				renderResume();
		}
		
		// onClosing() -- app is closing (may or may not get called by os)
		protected function onClosing(e :Event) :void
		{
			// call exit function
			onExiting(null);
		}

		// onContext3DCreate() -- context3D object is ready for use
		protected function onContext3DCreate(e :Event) :void
		{
			// verify stage3D
			if(!m_stage3D)
				return;
			
			// get valid context3D
			m_context3D = m_stage3D.context3D;
						
			// set context3D ready flag
			m_context3DReady = true;
			
			// clear requested flag
			m_context3DRequested = false;
			
			// restore render environment
			restoreRenderEnvironment();

			// swap out 2D launch image if needed
			if(m_launchImgVisible)
			{
				// take down 2D launch image
				m_sprite.removeChild(m_launchImg);
				
				// clear 2D launch image flag
				m_launchImgVisible = false;
				
				// prepare 3D launch image
				showLaunchImage3D();
			}
			
			// handle as resize event
			onResize(null);
		}
		
		// onDeactivate() -- app window is deactivating
		protected function onDeactivate(e :Event) :void
		{
			// check init
			if(!m_init)
				return;
			
			// lose focus
			onFocusLost();
			
			// pause render if needed
			if(!m_renderWhenIdle)
				renderPause();

			// save persistent data
			saveSharedData();
			
			// collect garbage
			System.gc();
			
			// output object usage
			trace("Object usage: vbuf = " + m_numVtxBufs  + "/" + m_maxVtxBufs  +
				               " ibuf = " + m_numIdxBufs  + "/" + m_maxIdxBufs  +
				                " tex = " + m_numTextures + "/" + m_maxTextures +
				               " view = " + m_numViews    + "/" + m_maxViews    +
				                " sfx = " + m_numSounds   + "/" + m_maxSounds   +
				                " mp3 = " + m_numMp3s     + "/" + m_maxMp3s);
		}

		// onExiting() -- app is exiting (unfortunately is usually not called)
		protected function onExiting(e :Event) :void
		{
			// check init
			if(!m_init)
				return;
			
			// exit app
			appExit();
			
			// kill all timers
			if(m_firstUpdateTimer) m_firstUpdateTimer.stop();
			if(m_frameRateTimer)   m_frameRateTimer  .stop();
			
			// stop music & sound
			musicStop();
			soundStopAll();
			
			// save persistent data
			saveSharedData();
			
			// clear init flag
			m_init = false;
		}
		
		// onFirstUpdateTimer() -- handle first-update timer event
		protected function onFirstUpdateTimer(e :TimerEvent) :void
		{
			// check context3d
			if(!m_context3DReady)
			{
				// restart this timer until ready
				m_firstUpdateTimer.reset();
				m_firstUpdateTimer.start();
			}
			else
			{
				// hide 3D launch image
				hideLaunchImage3D();
			
				// set init flag
				m_init = true;

				// init views
				viewInit();
				
				// get max display resolution
				if(m_messenger)
					m_maxDisplayRes = m_messenger.send("getLongestDisplaySide");
				
				// initialize app
				appInit();
				
				// set first frame skip tick (offset back to force one update)
				m_frameSkipTick = getTickCount() - m_frameDelay;
				
				// render one frame
				onFrameRateTimer(null);

				// start frame rate timer
				m_frameRateTimer.start();
				
				// set active flag
				m_appActive = true;
			}
		}
		
		// onFocusLost() -- app has lost focus
		public function onFocusLost() :void
		{
			// pause app
			appPause();

			// clear active flag
			m_appActive = false;
		}

		// onFocusReturned() -- app has regained focus
		public function onFocusReturned() :void
		{
			// resume app
			appResume();
			
			// set active flag
			m_appActive = true;
			
			// re-hide navigation on android
			if(m_osFlag == OSFLAG_ANDROID)
				if(m_messenger)
					m_messenger.send("hideSystemBar");
		}

		// onFrameRateTimer() -- handle per-frame timer events **time-critical
		protected function onFrameRateTimer(e :TimerEvent) :void
		{
			// verify context
			if(!m_context3DReady)
			{
				// request new context
				requestContext3D();
				
				// stop here
				return;
			}
			
			// prepare touches for use
			touchPreProcess();
			
			// get frames elapsed
			var framesElapsed :int = computeFramesElapsed();

			// update fps if needed
			if(m_trackFps)
				updateFpsView(framesElapsed);
			
			// perform updates with frame skip as needed
			for(; framesElapsed > 0; framesElapsed--)
				appUpdate();
			
			// clean up touches
			touchPostProcess();
			
			// update memory if needed
			if(m_trackMem)
				updateMemoryView();
			
			// render
			render();
		}
		
		// onKeyDown() -- handle key-down event **time-critical
		protected function onKeyDown(e :KeyboardEvent) :void
		{
			// halt event here
			e.stopPropagation();
			
			// check init
			if(!m_init)
				return;
			
			// check os
			switch(m_osFlag)
			{
			// android
			case(OSFLAG_ANDROID):
				
				// check key code
				switch(e.keyCode)
				{
				// back
				case(Keyboard.BACK):
					
					// handle as needed
					if(appAndroidBackKey())
						e.preventDefault();
					
					// stop here
					return;
				}
				
				// ok
				break;
			
			// windows
			case(OSFLAG_WINDOWS):
				
				// check key code
				switch(e.keyCode)
				{
				// enter
				case(13):
					
					// if alt+enter, toggle fullscreen
					if(e.altKey)
						if(m_messenger)
							m_messenger.send("toggleFullScreen");
					
					// stop here
					return;
				
				// escape
				case(27):
					
					// quit
					if(m_messenger)
						m_messenger.send("quit");
					
					// stop here
					return;
				}
				
				// ok
				break;
			}
			
			// pass to app
			appKeyDown(e);
		}
		
		// onKeyUp() -- handle key-up event **time-critical
		protected function onKeyUp(e :KeyboardEvent) :void
		{
			// halt event here
			e.stopPropagation();

			// check init
			if(!m_init)
				return;
			
			// pass to app
			appKeyUp(e);
		}

		// onMouseDown() -- user has touched/clicked on stage **time-critical
		internal function onMouseDown(e :MouseEvent) :void
		{
			// update raw position #0
			m_rawTouchX[0] = e.localX;
			m_rawTouchY[0] = e.localY;
			
			// set touching flag
			m_rawTouching[0] = true;
		}
		
		// onMouseLeave() -- user has moved mouse/stylus off of stage **time-critical
		internal function onMouseLeave(e :Event) :void
		{
			// clear both flags
			m_rawTouching   [0] = false;
			m_rawTouchActive[0] = false;
		}
		
		// onMouseMove() -- user has moved finger or mouse on stage **time-critical
		internal function onMouseMove(e :MouseEvent) :void
		{
			// update raw position #0
			m_rawTouchX[0] = e.localX;
			m_rawTouchY[0] = e.localY;
			
			// set active flag
			m_rawTouchActive[0] = true;
		}
		
		// onMouseUp() -- user has removed finger/released mouse from stage **time-critical
		internal function onMouseUp(e :MouseEvent):void
		{
			// update raw position
			m_rawTouchX[0] = e.localX;
			m_rawTouchY[0] = e.localY;
			
			// clear touching flag
			m_rawTouching[0] = false;
		}

		// onResize() -- handle resize event
		public function onResize(e :Event) :void
		{
			// resize internal data
			handleResize();
			
			// check launch image visibility
			if(m_launchImgVisible || m_launchImg3DVisible)
			{
				// resize launch image
				resizeLaunchImage();
			}
			else
			{
				// check init
				if(!m_init)
					return;
				
				// pass to app
				appResize();
				
				// check context3d
				if(m_context3DReady)
				{
					// update back buffer
					updateBackBuffer();
				
					// render one frame
					render();
				}
			}
		}

		// onTouchBegin() -- user has touched screen **time-critical
		internal function onTouchBegin(e :TouchEvent) :void
		{
			// halt event here
			e.stopPropagation();
			
			// get new index
			var idx :int = getAvailableTouchIndex(e);
			
			// check index
			if(idx >= 0)
			{
				// update raw position
				m_rawTouchX[idx] = e.localX;
				m_rawTouchY[idx] = e.localY;
				
				// update flags
				m_rawTouching   [idx] = true; 
				m_rawTouchActive[idx] = true;
			}
		}
		
		// onTouchEnd() -- user has removed finger from screen **time-critical
		internal function onTouchEnd(e: TouchEvent):void
		{
			// halt event here
			e.stopPropagation();

			// get matching index
			var idx :int = getMatchingTouchIndex(e);
			
			// check index
			if(idx >= 0)
			{
				// update raw position
				m_rawTouchX[idx] = e.localX;
				m_rawTouchY[idx] = e.localY;
				
				// update flags
				m_rawTouching   [idx] = false; 
				m_rawTouchActive[idx] = false;
			}
		}
		
		// onTouchMove() -- user has moved finger on screen **time-critical
		internal function onTouchMove(e :TouchEvent) :void
		{
			// halt event here
			e.stopPropagation();

			// get matching index
			var idx :int = getMatchingTouchIndex(e);

			// check index
			if(idx >= 0)
			{
				// update raw position
				m_rawTouchX[idx] = e.localX;
				m_rawTouchY[idx] = e.localY;
				
				// update flags
				m_rawTouching   [idx] = true; 
				m_rawTouchActive[idx] = true;
			}
		}
		
		// preInitGraphics() -- initialize bare-minumum graphics
		protected function preInitGraphics() :void
		{
			// set background color
			m_stage.color = m_bkgColor;

			// set stage to no-scale for proper sizing
			m_stage.scaleMode = StageScaleMode.NO_SCALE;
			
			// set default stage quality
			setStageQuality(QUALITY_LOW);
			
			// calculate render surface properties
			calculateRenderSizes();
			
			// check launch image
			if(m_launchImg)
			{
				// add to main sprite
				m_sprite.addChild(m_launchImg);
			
				// set flag
				m_launchImgVisible = true;

				// handle as resize event
				onResize(null);
			}
		}

		// render() -- per-frame render **time-critical
		protected function render() :void
		{
			// catch errors
			try
			{
				// clear viewport (required)
				m_context3D.clear(m_bkgColorRed,
								  m_bkgColorGreen,
								  m_bkgColorBlue,
								  1.0,
								  0.0,
								  0,
								  Context3DClearMask.COLOR);
			}
			catch(e: Error)
			{
				// check for loss of context & invalid back buffer
				if(e.errorID == ERROR_OBJECT_WAS_DISPOSED   ||
				   e.errorID == ERROR_BUFFER_NOT_CONFIGURED )
					m_context3DReady = false;
				else
					throw(e);
				
				// stop here
				return;
			}
			
			// let app do its rendering
			appRender();
			
			// render views
			if(m_viewRender)
				viewRender();

			// present scene
			m_context3D.present();
		}
		
		// renderPause() -- pause rendering (ignoring render-when-idle flag)
		public function renderPause() :void
		{
			// pause music/sound
			musicPause();
			soundStopAll();
			
			// stop timer
			if(m_frameRateTimer)
				m_frameRateTimer.stop();
			
			// render final frame
			render();
		}
		
		// renderResume() -- resume rendering (ignoring render-when-idle flag)
		public function renderResume() :void
		{
			// check frame-rate timer
			if(m_frameRateTimer)
			{
				// reset & resume timer
				m_frameRateTimer.reset();
				m_frameRateTimer.start();
			}
			
			// restart music
			musicResume();
		}
		
		// requestContext3D() -- request new context3D (avoiding repeated calls)
		protected function requestContext3D() :void
		{
			// already requested?
			if(m_context3DRequested)
				return;
			
			// verify stage3D
			if(m_stage3D)
			{
				// request new context
				m_stage3D.requestContext3D();
			
				// set flag
				m_context3DRequested = true;
			}
		}
		
		// resizeLaunchImage() -- update launch image per calculated sizes
		protected function resizeLaunchImage() :void
		{
			// verify image
			if(!m_launchImg)
				return;
			
			// check flags
			if(m_launchImgVisible)
			{
				// set bitmap to proper bounds
				m_launchImg.x      = m_boundsX;
				m_launchImg.y      = m_boundsY;
				m_launchImg.width  = m_boundsWidth;
				m_launchImg.height = m_boundsHeight;
			}
			else if(m_launchImg3DVisible)
			{
				// check context
				if(!m_context3DReady)
					return;

				// update back buffer
				updateBackBuffer();

				// compute offsets
				var ofsX :Number = -(m_boundsWidth  / m_viewportWidth);
				var ofsY :Number =  (m_boundsHeight / m_viewportHeight);
				
				// compute scale factors
				var scaleX :Number = ofsX * -2;
				var scaleY :Number = ofsY * -2;
				
				// new vertex constants
				var vtxConst :Vector.<Number> = new <Number>[
					scaleX, scaleY, 0, 0,
					ofsX,   ofsY,   0, 1];
				
				// update vertex constants
				shaderUpdateVertexConstants(m_launchImgShader, vtxConst);
				
				// render launch image
				indexBufferRender(m_launchImgIdxBuf);
				
				// present scene
				m_context3D.present();
			}
		}
		
		// restoreRenderEnvironment() -- reset all context3D flags for rendering
		protected function restoreRenderEnvironment() :void
		{
			// restore settings using saved values
			enableBackfaceCull  (m_backfaceCull);
			enableDepthTest     (m_depthTest);
			enableFrontfaceCull (m_frontfaceCull);
			enableGraphicsErrors(m_graphicsErrors);
			enableStencilTest   (m_stencilTest);
			setBlendMode        (m_blendMode);
			setStencilRef       (m_stencilRef);
			
			// restore render masks
			setRenderMask(m_maskRed,
						  m_maskGreen,
						  m_maskBlue,
						  m_maskAlpha);
			
			// re-upload all graphics objects
			uploadAllGraphicsObjects();

			// reset previous format count
			m_vtxBufPrevNumFmt = 0;
			
			// restore current objects
			shaderSetCurrent      (m_currShader);
			vertexBufferSetCurrent(m_currVtxBuf);
			
			// restore current textures
			for(var c :int = 0; c < AS3_TEXTURE_STAGES; c++)
				textureSetCurrent(m_currTexture[c], c);
		}

		// roundToEven() -- round a number to the nearest even value **time-critical
		protected function roundToEven(n :Number) :Number
		{
			// return rounded(n/2)*2
			return(Math.round(n / 2) * 2);
		}
		
		// saveSharedData() -- save global shared object (for persistent data)
		public function saveSharedData() :void
		{
			// flush the data (if avaialble)
			if(m_shared)
				m_shared.flush();
		}

		// setAntiAliasLevel() -- set level of anti-aliasing
		protected function setAntiAliasLevel(level :int) :void
		{
			// check level & save correct value
			switch(level)
			{
			// none (default)
			case(ANTIALIAS_NONE): default:
				
				// set proper level
				m_antiAliasLevel = 0;
				
				// ok
				break;
				
			// low (2 x 2 sample)
			case(ANTIALIAS_LOW):
				
				// set proper level
				m_antiAliasLevel = 2;
				
				// ok
				break;
				
			// high (4 x 4 sample)
			case(ANTIALIAS_HIGH):
				
				// set proper level
				m_antiAliasLevel = 4;
				
				// ok
				break;
				
			// max (16 x 16 sample)
			case(ANTIALIAS_MAX):
				
				// set proper level
				m_antiAliasLevel = 16;
				
				// ok
				break;
			}
				
			// handle as resize
			onResize(null);
		}

		// setBlendMode() -- set requested blend mode **time-critical
		protected function setBlendMode(blendMode :int) :void
		{
			// save mode
			m_blendMode = blendMode;
			
			// verify context
			if(!m_context3DReady)
				return;
			
			// blend factors
			var srcFactor  :String;
			var destFactor :String;

			// check mode
			switch(blendMode)
			{
			// none (default)
			case(BLEND_NONE): default:
				
				// set blend factors
				srcFactor  = Context3DBlendFactor.ONE;
				destFactor = Context3DBlendFactor.ZERO;
				
				// ok
				break;
			
			// alpha
			case(BLEND_ALPHA):
				
				// set blend factors
				srcFactor  = Context3DBlendFactor.SOURCE_ALPHA;
				destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
				
				// ok
				break;
			
			// additive
			case(BLEND_ADDITIVE):
				
				// set blend factors
				srcFactor  = Context3DBlendFactor.ONE;
				destFactor = Context3DBlendFactor.ONE;
				
				// ok
				break;
			
			// multiply
			case(BLEND_MULTIPLY):
				
				// set blend factors
				srcFactor  = Context3DBlendFactor.DESTINATION_COLOR;
				destFactor = Context3DBlendFactor.ZERO;
				
				// ok
				break;
			
			// screen
			case(BLEND_SCREEN):
				
				// set blend factors
				srcFactor  = Context3DBlendFactor.ONE;
				destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
				
				// ok
				break;
			}
			
			// set blend factors
			m_context3D.setBlendFactors(srcFactor, destFactor);
		}
		
		// setRenderMask() -- enable/disable masking of alpha values **time-critical
		protected function setRenderMask(maskRed   :Boolean,
										 maskGreen :Boolean,
										 maskBlue  :Boolean,
										 maskAlpha :Boolean) :void
		{
			// save flags
			m_maskRed   = maskRed;
			m_maskGreen = maskGreen;
			m_maskBlue  = maskBlue;
			m_maskAlpha = maskAlpha;
			
			// set requested mask
			if(m_context3DReady)
				m_context3D.setColorMask(m_maskRed,
										 m_maskGreen,
										 m_maskBlue,
										 m_maskAlpha);
		}
		
		// setStageQuality() -- set desired stage quality level (probably no effect as used, but hey...)
		protected function setStageQuality(flag :int) :void
		{
			// set based on given flag
			if(m_stage)
				switch(flag)
				{
					default:
					case(QUALITY_LOW):    m_stage.quality = StageQuality.LOW;    break;
					case(QUALITY_MEDIUM): m_stage.quality = StageQuality.MEDIUM; break;
					case(QUALITY_HIGH):   m_stage.quality = StageQuality.HIGH;   break;
					case(QUALITY_BEST):   m_stage.quality = StageQuality.BEST;   break;
				}
		}
		
		// setStencilRef() -- set stencil buffer reference value **time-critical
		protected function setStencilRef(stencilRef :uint) :void
		{
			// save value
			m_stencilRef = stencilRef;
			
			// set value
			if(m_context3DReady)
				m_context3D.setStencilReferenceValue(stencilRef);
		}

		// shaderAdd() -- add a new shader object
		protected function shaderAdd(vtxShader :String,
									 pxlShader :String,
									 vtxConst  :Vector.<Number> = null,
									 pxlConst  :Vector.<Number> = null) :int
		{
			// Shader registers:
			//   All registers include four components:
			//   .x, .y. ,z, .w (equivalent to .r, .g, .b, .a)

			// Vertex shader: (input)
			//   vc0-vc127 -- program constants (as set by Context3D.setProgramConstants...)
			//                can be used to store matrices, lighting info, materials data, etc.
			//   va0-va7   -- vertex data (as set by Context3D.setVertexBufferAt)
			//                each vertex runs through shader program here, one-by-one

			// Vertex shader: (intermediate)
			//   vt0-vt7 -- temporary (use as needed)
			
			// Vertex shader: (output)
			//   op    -- output vertex (in x, y screen coordinates; z = depth)
			//   v0-v7 -- varying (will be interpolated between vertices for each pixel)
			//            use to store vertex color values, uv texture coords, etc.
			
			// Pixel/fragment shader: (input)
			//   fc0-fc27 -- program constants (as set by Context3D.setProgramConstants...)
			//   v0-v7    -- interpolated values (passed from vertex shader)
			//   fs0-fs7  -- texture sampler (each texture as set by Context3D.setTextureAt) 
			
			// Pixel/fragment shader: (intermediate)
			//   ft0-ft7 -- temporary (use as needed)
			
			// Pixel/fragment shader: (output)
			//   oc -- final output color for pixel
			
			// prepare shader object
			// use 1 large vtx buffer & 1 index buffer for views
			// associate constants with program & store/upload with program
			// use flags/methods to set/restore all render states (blend factors, color mask, culling, depth test, fill mode, stencil info, etc.)
			
			// get next shader
			var idx :int = shaderGetNext();
			
			// stop at invalid index
			if(idx < 0)
				return(idx);
			
			// set initial constants
			if(vtxConst) shaderUpdateVertexConstants(idx, vtxConst);
			if(pxlConst) shaderUpdatePixelConstants (idx, pxlConst);
			
			// set initial shader programs
			shaderUpdatePrograms(idx, vtxShader, pxlShader);
			
			// return index
			return(idx);
		}
		
		// shaderGetNext() -- retrieve next available shader object
		protected function shaderGetNext() :int
		{
			// check for overflow
			if(m_numShaders >= m_maxShaders)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.shaderGetNext(): " +
								"Maximum number of shaders exceeded");
				
				// stop here
				return(-1);
			}
			
			// verify context3D
			if(!m_context3DReady)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.shaderGetNext(): " +
								"No render surface is available");
				
				// stop here
				return(-1);
			}
			
			// create arrays if needed
			if(!m_shaderProgram     ) m_shaderProgram      = new Vector.<Program3D>        (m_maxShaders, true);
			if(!m_shaderVtxOpcodes  ) m_shaderVtxOpcodes   = new Vector.<String>           (m_maxShaders, true);
			if(!m_shaderPxlOpcodes  ) m_shaderPxlOpcodes   = new Vector.<String>           (m_maxShaders, true);
			if(!m_shaderVtxAssembler) m_shaderVtxAssembler = new Vector.<AGALMiniAssembler>(m_maxShaders, true);
			if(!m_shaderPxlAssembler) m_shaderPxlAssembler = new Vector.<AGALMiniAssembler>(m_maxShaders, true);
			if(!m_shaderVtxConst    ) m_shaderVtxConst     = new Vector.<Vector.<Number>>  (m_maxShaders, true);
			if(!m_shaderPxlConst    ) m_shaderPxlConst     = new Vector.<Vector.<Number>>  (m_maxShaders, true);
			
			// init shader data
			m_shaderProgram     [m_numShaders] = null;
			m_shaderVtxOpcodes  [m_numShaders] = null;
			m_shaderPxlOpcodes  [m_numShaders] = null;
			m_shaderVtxAssembler[m_numShaders] = new AGALMiniAssembler();
			m_shaderPxlAssembler[m_numShaders] = new AGALMiniAssembler();
			m_shaderVtxConst    [m_numShaders] = new Vector.<Number>;
			m_shaderPxlConst    [m_numShaders] = new Vector.<Number>;
			
			// return index & increment
			return(m_numShaders++);
		}
		
		// shaderSetCurrent() -- set shader to be used for rendering **time-critical
		protected function shaderSetCurrent(idx :int = -1) :void
		{
			// save as current
			m_currShader = idx;
			
			// check index
			if(idx < 0)
			{
				// clear program
				m_context3D.setProgram(null);
			}
			else
			{
				// set program
				m_context3D.setProgram(m_shaderProgram[idx]);
				
				// set vertex constants
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,
														  0,
														  m_shaderVtxConst[idx]);
				
				// set pixel constants
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,
														  0,
														  m_shaderPxlConst[idx]);
			}
		}
		
		// shaderUpdatePixelConstants() -- update constants for pixel shader (must update in multiples of 4!) **time-critical
		protected function shaderUpdatePixelConstants(idx    :int,
													  values :Vector.<Number>,
													  start  :int     = 0,
													  store  :Boolean = true) :void
		{
			// check storage flag
			if(store)
			{
				// counters
				var n1 :int;
				var n2 :int = start;
				
				// copy each value
				for(n1 = 0; n1 < values.length; n1++)
					m_shaderPxlConst[idx][n2++] = values[n1];
			}

			// apply if currently selected
			if(m_currShader == idx)
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT,
								 						  start,
														  values);
		}
		
		// shaderUpdatePrograms() -- update shader with new programs
		protected function shaderUpdatePrograms(idx       :int,
												vtxShader :String,
												pxlShader :String) :void
		{
			// store shader opcodes
			m_shaderVtxOpcodes[idx] = vtxShader;
			m_shaderPxlOpcodes[idx] = pxlShader;
			
			// assemble shaders
			m_shaderVtxAssembler[idx].assemble(Context3DProgramType.VERTEX,   vtxShader);
			m_shaderPxlAssembler[idx].assemble(Context3DProgramType.FRAGMENT, pxlShader);
			
			// upload new shader
			shaderUpload(idx, true);
			
			// re-set if currently selected
			if(m_currShader == idx)
				shaderSetCurrent(idx);
		}
		
		// shaderUpdateVertexConstants() -- update constants for vertex shader (must update in multiples of 4!) **time-critical
		protected function shaderUpdateVertexConstants(idx    :int,
													   values :Vector.<Number>,
													   start  :int     = 0,
													   store  :Boolean = true) :void
		{
			// check storage flag
			if(store)
			{
				// counters
				var n1 :int;
				var n2 :int = start;
				
				// copy each value
				for(n1 = 0; n1 < values.length; n1++)
					m_shaderVtxConst[idx][n2++] = values[n1];
			}
			
			// apply if currently selected
			if(m_currShader == idx)
				m_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX,
														  start,
														  values);
		}

		// shaderUpload() -- upload shader to graphics card **time-critical
		protected function shaderUpload(idx      :int,
										recreate :Boolean = false) :void
		{
			// verify context
			if(!m_context3DReady)
				return;

			// catch context loss
			try
			{
				// create new program if needed
				if(recreate) // || !m_shaderProgram[idx]) // <-- no need to check
					m_shaderProgram[idx] = m_context3D.createProgram();
				
				// upload shader programs to context
				m_shaderProgram[idx].upload(m_shaderVtxAssembler[idx].agalcode,
	 										m_shaderPxlAssembler[idx].agalcode);
			}
			catch(e: Error)
			{
				// check for loss of context
				if(e.errorID == ERROR_OBJECT_WAS_DISPOSED)
					m_context3DReady = false;
				else
					throw(e);
			}
		}
	
		// sharedData() -- retrieve shared data object
		public function sharedData() :Object
		{
			// return the data object
			return(m_shared ? m_shared.data : null);
		}

		// showLaunchImage3D() -- prepare the 3D-rendered version of the launch image
		protected function showLaunchImage3D() :void
		{
			// vertex shader program
			var vtxShader :String = "mul vt0, vc0, va0\n" + // scale to bounds size
									"add op,  vc1, vt0\n" + // translate to origin
									"mov v0,  va1\n"      ; // copy tex coords for fragment
			
			// vertex shader constants (dummy values to start)
			var vtxConst :Vector.<Number> = new <Number>[
				 2, -2, 0, 0,  // scale factor
				-1,  1, 0, 1]; // translation factor
			
			// pixel shader program
			var pxlShader :String = "tex oc, v0, fs0 <2d,clamp,linear>\n"; // apply texture map using stored coords
			
			// vertices
			var vertices :Vector.<Number> = new <Number>[
				0, 0, 0, 0, // x, y, u, v
				1, 0, 1, 0,
				1, 1, 1, 1,
				0, 1, 0, 1];
  			
			// vertex buffer format
			var vtxBufFormat :Vector.<String> = new <String>[
				Context3DVertexBufferFormat.FLOAT_2,  // x, y
				Context3DVertexBufferFormat.FLOAT_2]; // u, v
			
			// indices
			var indices :Vector.<uint> = new <uint>[
				0, 1, 2,
				2, 3, 0];
			
			// add objects for launch image
			m_launchImgShader  = shaderAdd(vtxShader, pxlShader, vtxConst);
			m_launchImgVtxBuf  = vertexBufferAdd(vertices, vtxBufFormat, false);
			m_launchImgIdxBuf  = indexBufferAdd(indices, false);
			m_launchImgTexture = textureAddFromBitmap(m_launchImg);

			// set required objects
			shaderSetCurrent      (m_launchImgShader);
			vertexBufferSetCurrent(m_launchImgVtxBuf);
			textureSetCurrent     (m_launchImgTexture);
			
			// set 3D launch image flag
			m_launchImg3DVisible = true;
		}

		// soundStopAll() -- immediately stop all playing sounds **time-critical
		protected function soundStopAll() :void
		{
			trace("soundStopAll");
		}
		
		// testLossOfContext() -- force loss & reset of context3D object
		protected function testLossOfContext() :void
		{
			// dispose context
			if(m_context3D)
				m_context3D.dispose();
		}

		// textureAdd() -- add new blank texture
		protected function textureAdd(width        :int,
									  height       :int,
									  transparent  :Boolean = true,
									  fillColor    :uint    = 0x00000000, // 0xAARRGGBB
									  renderTarget :Boolean = false) :int
		{
			// get next texture
			var idx :int = textureGetNext();
			
			// stop at invalid index
			if(idx < 0)
				return(idx);
			
			// copy render target flag
			m_texIsRenderTarget[idx] = renderTarget;
			
			// set base size
			m_texBaseWidth [idx] = width;
			m_texBaseHeight[idx] = height;
			
			// set power-of-2 size
			m_texPO2Width [idx] = nextGreaterPO2(m_texBaseWidth [idx]);
			m_texPO2Height[idx] = nextGreaterPO2(m_texBaseHeight[idx]);
			
			// create bitmap data
			m_texBitmapData[idx] = new BitmapData(width,
												  height,
												  transparent,
												  fillColor);
			
			// upload texture
			textureUpload(idx, true);
			
			// return index
			return(idx);
		}

		// textureAddFromBitmap() -- add new texture from bitmap
		protected function textureAddFromBitmap(bitmap       :Bitmap,
									  			renderTarget :Boolean = false) :int
		{
			// just use bitmap data
			return(textureAddFromBitmapData(bitmap.bitmapData, renderTarget));
		}
		
		// textureAddFromBitmapData() -- add new texture from bitmap data
		protected function textureAddFromBitmapData(bitmapData   :BitmapData,
									  				renderTarget :Boolean = false) :int
		{
			// get next texture
			var idx :int = textureGetNext();
			
			// stop at invalid index
			if(idx < 0)
				return(idx);
			
			// copy render target flag
			m_texIsRenderTarget[idx] = renderTarget;
			
			// set base size
			m_texBaseWidth [idx] = bitmapData.width;
			m_texBaseHeight[idx] = bitmapData.height;
			
			// set power-of-2 size
			m_texPO2Width [idx] = nextGreaterPO2(m_texBaseWidth [idx]);
			m_texPO2Height[idx] = nextGreaterPO2(m_texBaseHeight[idx]);

			// copy bitmap data
			m_texBitmapData[idx] = bitmapData;
			
			// upload texture
			textureUpload(idx, true);
			
			// return index
			return(idx);
		}
		
		// textureGetNext() -- get next available texture
		protected function textureGetNext() :int
		{
			// check for overflow
			if(m_numTextures >= m_maxTextures)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.textureGetNext(): " +
								"Maximum number of textures exceeded");
				
				// stop here
				return(-1);
			}
			
			// verify context3D
			if(!m_context3DReady)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.textureGetNext(): " +
								"No render surface is available");
				
				// stop here
				return(-1);
			}
			
			// create arrays if needed
			if(!m_texTexture       ) m_texTexture        = new Vector.<Texture>   (m_maxTextures, true);
			if(!m_texIsRenderTarget) m_texIsRenderTarget = new Vector.<Boolean>   (m_maxTextures, true);
			if(!m_texBaseWidth     ) m_texBaseWidth      = new Vector.<int>       (m_maxTextures, true);
			if(!m_texBaseHeight    ) m_texBaseHeight     = new Vector.<int>       (m_maxTextures, true);
			if(!m_texPO2Width      ) m_texPO2Width       = new Vector.<int>       (m_maxTextures, true);
			if(!m_texPO2Height     ) m_texPO2Height      = new Vector.<int>       (m_maxTextures, true);
			if(!m_texBitmapData    ) m_texBitmapData     = new Vector.<BitmapData>(m_maxTextures, true);
			
			// init texture data
			m_texTexture       [m_numTextures] = null;
			m_texIsRenderTarget[m_numTextures] = false;
			m_texBaseWidth     [m_numTextures] = 0;
			m_texBaseHeight    [m_numTextures] = 0;
			m_texPO2Width      [m_numTextures] = 0;
			m_texPO2Height     [m_numTextures] = 0;
			m_texBitmapData    [m_numTextures] = null;
			
			// return index & increment
			return(m_numTextures++);
		}
		
		// textureSetCurrent() -- set current texture **time-critical
		protected function textureSetCurrent(idx     :int = -1,
											 sampler :int =  0) :void
		{
			// save as current
			m_currTexture[sampler] = idx;
			
			// set to context at requested sampler
			m_context3D.setTextureAt(sampler, (idx < 0) ? null : m_texTexture[idx]);
		}
		
		// textureUpload() -- upload texture to graphics card **time-critical
		protected function textureUpload(idx      :int,
										 recreate :Boolean = false) :void
		{
			// verify context
			if(!m_context3DReady)
				return;

			// catch context loss
			try
			{
				// create new texture if needed
				if(recreate) // || !m_texTexture[idx]) <-- no need to check
					m_texTexture[idx] = m_context3D.createTexture(m_texPO2Width [idx],
																  m_texPO2Height[idx],
																  Context3DTextureFormat.BGRA,
																  m_texIsRenderTarget[idx]);
				
				// upload bitmap data to context
				m_texTexture[idx].uploadFromBitmapData(m_texBitmapData[idx]);
			}
			catch(e: Error)
			{
				// check for loss of context
				if(e.errorID == ERROR_OBJECT_WAS_DISPOSED)
					m_context3DReady = false;
				else
					throw(e);
			}
		}
		
		// touchPreProcess() -- prepare touch data for current use **time-critical
		protected function touchPreProcess() :void
		{
			// process each touch
			for(var c :int = 0; c < m_maxTouches; c++)
			{
				// check active flag
				if(m_rawTouchActive[c])
				{
					// scale to target area
					var x :Number = ((m_rawTouchX[c] - m_swfWidth2)  * m_touchScaleX) + m_baseWidth2;
					var y :Number = ((m_rawTouchY[c] - m_swfHeight2) * m_touchScaleY) + m_baseHeight2;
					
					// clip to visible area
					if(x < m_leftEdge)    x = m_leftEdge;
					if(x > m_rightEdge1)  x = m_rightEdge1;
					if(y < m_topEdge)     y = m_topEdge;
					if(y > m_bottomEdge1) y = m_bottomEdge1;
					
					// apply adjusted values to world view
					m_touchX[c] = Math.round(x - m_worldX) as int;
					m_touchY[c] = Math.round(y - m_worldY) as int;
				}
			
				// copy flags
				m_touching   [c] = m_rawTouching   [c];
				m_touchActive[c] = m_rawTouchActive[c];
			}
		}
		
		// touchPostProcess() -- prepare touch data for next use **time-critical
		protected function touchPostProcess() :void
		{
			// retain touching flags
			for(var c :int = 0; c < m_maxTouches; c++)
				m_wasTouching[c] = m_touching[c];
		}
		
		// updateBackBuffer() -- set/restore size/position of back buffer
		protected function updateBackBuffer() :void
		{
			// are we ready?
			if(!m_context3DReady)
				return;
			
			// check against minimum viewport size
			if(m_viewportWidth  < 32 ||
			   m_viewportHeight < 32 )
			{
				// we are minimzed; stop here
				return;
			}
			
			// update viewport position
			m_stage3D.x = m_viewportX;
			m_stage3D.y = m_viewportY;
			
			// catch errors
			try
			{
				// reconfigure back buffer
				m_context3D.configureBackBuffer(m_viewportWidth,
												m_viewportHeight,
												m_antiAliasLevel,
												false);
				
				// clear viewport
				m_context3D.clear(m_bkgColorRed,
								  m_bkgColorGreen,
								  m_bkgColorBlue,
								  1.0,
								  0.0,
								  0,
								  Context3DClearMask.COLOR);
			}
			catch(e: Error)
			{
				// check for loss of context
				if(e.errorID == ERROR_OBJECT_WAS_DISPOSED)
					m_context3DReady = false;
				else
					throw(e);
			}
		}
		
		// updateFpsView() -- update texture & view associated with FPS tracking **SLOW!
		protected function updateFpsView(framesElapsed :int) :void
		{
			// increment frames-per-second
			m_fps++;

			// increment updates-per-second
			m_ups += framesElapsed;
			
			// get current tick
			var tick :int = getTickCount();
			
			// check for overflow
			if(tick >= m_fpsNextTick)
			{
				// clip fps & ups at 99
				if(m_fps > 99) m_fps = 99;
				if(m_ups > 99) m_ups = 99;
				
				// update frame rate texture
				var bmpData :BitmapData = viewGetBitmapData(m_fpsView);
				debugRectToBitmapData(bmpData, 0, 0, 31, 7, 0xB0000000);
				debugTextToBitmapData(bmpData, ((m_fps < 10) ? "0" + m_fps : String(m_fps)) + "/" + ((m_ups < 10) ? "0" + m_ups : String(m_ups)), 1, 1);
				viewSaveBitmapData(m_fpsView);
			
				// move to top-center
				viewSetPosition(m_fpsView, (m_baseWidth - 30) / 2, m_topEdge); 
				
				// set next tick
				m_fpsNextTick = tick + 1000;
				
				// reset fps & counters
				m_fps = 0;
				m_ups = 0;
			}
		}
		
		// updateMemoryView() -- update texture & view associated with memory tracking **SLOW!
		protected function updateMemoryView() :void
		{
			// get current tick
			var tick :int = getTickCount();
			
			// check for overflow
			if(tick >= m_memNextTick)
			{
				// get memory values (in kb)
				var memUsed  :Number = System.totalMemoryNumber / 1024;
				var memTotal :Number = System.privateMemory     / 1024;
				
				// create output string
				var output :String;
				
				// add memory used
				if(memUsed < 1024)
					output = Math.round(memUsed) + "K";
				else if(memUsed < (1024 * 1024))
					output = Math.round(memUsed / 1024) + "M";
				else if(memUsed < (1024 * 1024 * 1024))
					output = Math.round(memUsed / (1024 * 1024)) + "G";
				else if(memUsed < (1024 * 1024 * 1024 * 1024))
					output = Math.round(memUsed / (1024 * 1024 * 1024)) + "T";
				else
					output = "a lot";
				
				// add separator
				output = output.concat("/");
				
				// add total memory
				if(memTotal < 1024)
					output = output.concat(Math.round(memTotal) + "K");
				else if(memTotal < (1024 * 1024))
					output = output.concat(Math.round(memTotal / 1024) + "M");
				else if(memTotal < (1024 * 1024 * 1024))
					output = output.concat(Math.round(memTotal / (1024 * 1024)) + "G");
				else if(memTotal < (1024 * 1024 * 1024 * 1024))
					output = output.concat(Math.round(memTotal / (1024 * 1024 * 1024)) + "T");
				else
					output = output.concat("a lot");
				
				// update memory texture
				var bmpData :BitmapData = viewGetBitmapData(m_memView);
				debugRectToBitmapData(bmpData, 0, 0, 128, 8, 0x00000000);
				debugRectToBitmapData(bmpData, 64 - (output.length * 3), 0, (output.length * 6) + 1, 7, 0xB0000000);
				debugTextToBitmapData(bmpData, output, 65 - (output.length * 3), 1);
				viewSaveBitmapData(m_memView);
				
				// move to bottom-center
				viewSetPosition(m_memView, (m_baseWidth / 2) - 64, m_bottomEdge - 7);
				
				// set next tick
				m_memNextTick = tick + 1000;
			}
		}
		
		// uploadAllGraphicsObjects() -- re-upload all objects after creation of new context
		protected function uploadAllGraphicsObjects() :void
		{
			// are we ready?
			if(!m_context3DReady)
				return;
			
			// counter
			var idx :int;
			
			// re-upload all objects
			if(m_numShaders)  for(idx = 0; idx < m_numShaders;  idx++) shaderUpload      (idx, true);
			if(m_numVtxBufs)  for(idx = 0; idx < m_numVtxBufs;  idx++) vertexBufferUpload(idx, true);
			if(m_numIdxBufs)  for(idx = 0; idx < m_numIdxBufs;  idx++) indexBufferUpload (idx, true);
			if(m_numTextures) for(idx = 0; idx < m_numTextures; idx++) textureUpload     (idx, true);
		}
		
		// vertexBufferAdd() -- add new vertex buffer object
		protected function vertexBufferAdd(vertices     :Vector.<Number>,
										   vtxBufFormat :Vector.<String>,
										   isStatic     :Boolean = true) :int
		{
			// get next vertex buffer
			var idx :int = vertexBufferGetNext();
			
			// stop at invalid index
			if(idx < 0)
				return(idx);
			
			// set buffer format
			if(vtxBufFormat)
				vertexBufferReformat(idx, vtxBufFormat, isStatic);

			// set initial vertices
			if(vertices)
				vertexBufferUpdateVertices(idx, vertices);
			
			// return index
			return(idx);
		}
		
		// vertexBufferGetNext() -- get next avaialble vertex buffer
		protected function vertexBufferGetNext() :int
		{
			// check for overflow
			if(m_numVtxBufs >= m_maxVtxBufs)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.vertexBufferGetNext(): " +
								"Maximum number of vertex buffers exceeded");
				
				// stop here
				return(-1);
			}
			
			// verify context3D
			if(!m_context3DReady)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.vertexBufferGetNext(): " +
								"No render surface is available");
				
				// stop here
				return(-1);
			}
			
			// create arrays if needed
			if(!m_vtxBufBuffer    ) m_vtxBufBuffer     = new Vector.<VertexBuffer3D> (m_maxVtxBufs, true);
			if(!m_vtxBufIsStatic  ) m_vtxBufIsStatic   = new Vector.<Boolean>        (m_maxVtxBufs, true);
			if(!m_vtxBufNumData   ) m_vtxBufNumData    = new Vector.<int>            (m_maxVtxBufs, true);
			if(!m_vtxBufDataPerVtx) m_vtxBufDataPerVtx = new Vector.<int>            (m_maxVtxBufs, true);
			if(!m_vtxBufNumVtx    ) m_vtxBufNumVtx     = new Vector.<int>            (m_maxVtxBufs, true);
			if(!m_vtxBufVertices  ) m_vtxBufVertices   = new Vector.<Vector.<Number>>(m_maxVtxBufs, true);
			if(!m_vtxBufNumFormat ) m_vtxBufNumFormat  = new Vector.<int>            (m_maxVtxBufs, true);
			if(!m_vtxBufFmtOffsets) m_vtxBufFmtOffsets = new Vector.<Vector.<int>>   (m_maxVtxBufs, true);
			if(!m_vtxBufFmtTypes  ) m_vtxBufFmtTypes   = new Vector.<Vector.<String>>(m_maxVtxBufs, true);
			
			// init vertex buffer data
			m_vtxBufBuffer    [m_numVtxBufs] = null;
			m_vtxBufIsStatic  [m_numVtxBufs] = false;
			m_vtxBufNumData   [m_numVtxBufs] = 0;
			m_vtxBufDataPerVtx[m_numVtxBufs] = 0;
			m_vtxBufNumVtx    [m_numVtxBufs] = 0;
			m_vtxBufVertices  [m_numVtxBufs] = new Vector.<Number>;
			m_vtxBufNumFormat [m_numVtxBufs] = 0;
			m_vtxBufFmtOffsets[m_numVtxBufs] = new Vector.<int>;
			m_vtxBufFmtTypes  [m_numVtxBufs] = new Vector.<String>;
			
			// return index & increment
			return(m_numVtxBufs++);
		}

		// vertexBufferReformat() -- set up vertex buffer based on given format
		protected function vertexBufferReformat(idx          :int,
												vtxBufFormat :Vector.<String>,
												isStatic     :Boolean = false) :void
		{
			// copy new static flag
			m_vtxBufIsStatic[idx] = isStatic;
			
			// reset vertex array
			m_vtxBufVertices[idx].length = 0;
			
			// reset remaining vertex data
			m_vtxBufNumData   [idx] = 0;
			m_vtxBufDataPerVtx[idx] = 0;
			m_vtxBufNumFormat [idx] = 0;
						
			// process each format
			for(var c :int = 0; c < vtxBufFormat.length; c++)
			{
				// set offset for current type
				m_vtxBufFmtOffsets[idx][c] = m_vtxBufDataPerVtx[idx];
				
				// copy current type
				m_vtxBufFmtTypes[idx][c] = vtxBufFormat[c];
			
				// add one format type
				m_vtxBufNumFormat[idx]++;
				
				// data count
				var numData :int;
				
				// set data count based on type
				switch(vtxBufFormat[c])
				{
				case(Context3DVertexBufferFormat.BYTES_4): numData = 1; break;
				case(Context3DVertexBufferFormat.FLOAT_1): numData = 1; break;
				case(Context3DVertexBufferFormat.FLOAT_2): numData = 2; break;
				case(Context3DVertexBufferFormat.FLOAT_3): numData = 3; break;
				case(Context3DVertexBufferFormat.FLOAT_4): numData = 4; break;
				
				// not recognized
				default:
					throw new Error("com.wb.software.WBEngine.vertexBufferReformat(): " +
									"Invalid vertex buffer format");
				}
				
				// add data count to total
				m_vtxBufDataPerVtx[idx] += numData;
			}
		}
		
		// vertexBufferSetCurrent() -- set current vertex buffer **time-critical
		protected function vertexBufferSetCurrent(idx :int = -1) :void
		{
			// counter
			var c :int;

			// save as current
			m_currVtxBuf = idx;
			
			// check index
			if(idx >= 0)
			{
				// get number of format items
				var numFmt :int = m_vtxBufNumFormat[idx];
				
				// set all saved vertex types
				for(c = 0; c < numFmt; c++)
					m_context3D.setVertexBufferAt(c,
												  m_vtxBufBuffer    [idx], 
												  m_vtxBufFmtOffsets[idx][c],
												  m_vtxBufFmtTypes  [idx][c]);
				
				// reset any leftovers
				for(; c < m_vtxBufPrevNumFmt; c++)
					m_context3D.setVertexBufferAt(c, null, 0, null);
			
				// save previous number
				m_vtxBufPrevNumFmt = numFmt;
			}
			else
			{
				// reset all
				for(c = 0; c < m_vtxBufPrevNumFmt; c++)
					m_context3D.setVertexBufferAt(c, null, 0, null);
			
				// reset previous number
				m_vtxBufPrevNumFmt = 0;
			}
		}
		
		// vertexBufferUpdateVertices() -- set new vertices for vertex buffer **time-critical
		protected function vertexBufferUpdateVertices(idx    :int,
													  values :Vector.<Number>,
													  start  :int = 0) :void
		{
			// counters
			var n1 :int;
			var n2 :int = start;
			
			// copy each value
			for(n1 = 0; n1 < values.length; n1++)
				m_vtxBufVertices[idx][n2++] = values[n1];
			
			// check for overflow (n2 = numData)
			if(n2 > m_vtxBufNumData[idx])
			{
				// set new max
				m_vtxBufNumData[idx] = n2;
				
				// compute new vertex count
				m_vtxBufNumVtx[idx] = m_vtxBufNumData[idx] / m_vtxBufDataPerVtx[idx];
				
				// re-create & upload buffer
				vertexBufferUpload(idx, true);
			}
			else
			{
				// re-upload buffer
				vertexBufferUpload(idx);
			}
		}

		// vertexBufferUpload() -- upload vertex buffer to graphics card **time-critical
		protected function vertexBufferUpload(idx      :int,
											  recreate :Boolean = false) :void
		{
			// verify context
			if(!m_context3DReady)
				return;

			// catch context loss
			try
			{
				// re-create buffer if needed
				if(recreate) // || !m_vtxBufBuffer[idx]) <-- no need to check
					m_vtxBufBuffer[idx] = m_context3D.createVertexBuffer(m_vtxBufNumVtx    [idx] ,
																		 m_vtxBufDataPerVtx[idx] ,
																		 m_vtxBufIsStatic  [idx] ? Context3DBufferUsage.STATIC_DRAW
																							     : Context3DBufferUsage.DYNAMIC_DRAW);
				
				// upload vertex buffer
				m_vtxBufBuffer[idx].uploadFromVector(m_vtxBufVertices[idx],
													 0,
													 m_vtxBufNumVtx[idx]);
			}
			catch(e: Error)
			{
				// check for loss of context
				if(e.errorID == ERROR_OBJECT_WAS_DISPOSED)
					m_context3DReady = false;
				else
					throw(e);
			}
		}
		
		// viewAdd() -- add uninitialized view
		protected function viewAdd() :int
		{
			// get next view
			var idx :int = viewGetNext();
			
			// return new index
			return(idx);
		}
		
		// viewAddFpsDisplay() -- add view to display frame count
		protected function viewAddFpsDisplay() :int
		{
			// check existing view
			if(m_fpsView == -1)
			{
				// create texture
				m_fpsTex = textureAdd(32, 8, true, 0x00000000);
				
				// create view
				m_fpsView = viewAddFromTexture(m_fpsTex);
			}
			
			// make sure view is visible
			viewSetVisible(m_fpsView, true);
			
			// begin tracking
			m_trackFps = true;
			
			// return index
			return(m_fpsView);
		}
		
		// viewAddFromBitmap() -- add view using bitmap object
		protected function viewAddFromBitmap(bitmap :Bitmap,
											 width  :Number = 0,
											 height :Number = 0) :int
		{
			// add texture
			var tx :int = textureAddFromBitmap(bitmap);
			
			// add view & return index
			return(tx >= 0 ? viewAddFromTexture(tx, width, height) : -1);
		}
		
		// viewAddFromTexture() -- add view using existing texture
		protected function viewAddFromTexture(texIdx :int,
											  width  :Number = 0,
											  height :Number = 0) :int
		{
			// get next view
			var idx :int = viewGetNext();
			
			// stop at invalid index
			if(idx < 0)
				return(idx);
			
			// verify texture
			if(texIdx < 0)
				throw new Error("com.wb.software.WBEngine.viewAddFromTexture(): " +
								"Invalid texture index");
			
			// prepare view data
			m_viewTexIdx [idx] = texIdx;
			m_viewPosX   [idx] = 0;
			m_viewPosY   [idx] = 0;
			m_viewWidth  [idx] = width  ? width  : m_texBaseWidth [texIdx] as Number;
			m_viewHeight [idx] = height ? height : m_texBaseHeight[texIdx] as Number;
			m_viewVisible[idx] = true;

			// return new index
			return(idx);
		}
		
		// viewAddFromTextureInv() -- add invisible view using existing texture
		protected function viewAddFromTextureInv(texIdx :int,
											     width  :Number = 0,
											     height :Number = 0) :int
		{
			// create view
			var idx :int = viewAddFromTexture(texIdx, width, height);
			
			// make view invisible
			viewSetVisible(idx, false);
			
			// return index
			return(idx);
		}
		
		// viewAddLaunchImage() -- add & display view in place of launch image
		protected function viewAddLaunchImage() :int
		{
			// check for existing view
			if(m_launchImgView == -1)
			{
				// create view from launch image texture
				m_launchImgView = viewAddFromTexture(m_launchImgTexture,
												  	 m_extWidth, m_extHeight);
				
				// set launch image view position
				viewSetPosition(m_launchImgView, m_extX, m_extY);
			}
			
			// make sure view is visible
			viewSetVisible(m_launchImgView, true);
			
			// return index
			return(m_launchImgView);
		}
		
		// viewAddMemoryDisplay() -- add view to display memory usage
		protected function viewAddMemoryDisplay() :int
		{
			// check for existing view
			if(m_memView == -1)
			{
				// create texture
				m_memTex = textureAdd(128, 8, true, 0x00000000);
				
				// create view
				m_memView = viewAddFromTexture(m_memTex);
			}
			
			// make sure view is visible
			viewSetVisible(m_memView, true);
			
			// begin tracking
			m_trackMem = true;
			
			// return index
			return(m_memView);
		}
		
		// viewGetBaseHeight() -- get height of view's base texture **time-critical
		protected function viewGetBaseHeight(idx :int) :Number
		{
			// return requested value
			return(m_texBaseHeight[m_viewTexIdx[idx]]);
		}
		
		// viewGetBaseWidth() -- get width if view's base texture **time-critical
		protected function viewGetBaseWidth(idx :int) :Number
		{
			// return requested value
			return(m_texBaseWidth[m_viewTexIdx[idx]]);
		}
		
		// viewGetBitmapData() -- get bitmap data of view's currently assigned texture **time-critical
		protected function viewGetBitmapData(idx :int) :BitmapData
		{
			// return requested object
			return(m_texBitmapData[m_viewTexIdx[idx]]);
		}
		
		// viewGetHeight() -- get height for view **time-critical
		protected function viewGetHeight(idx :int) :Number
		{
			// return requested value
			return(m_viewHeight[idx]);
		}
		
		// viewGetNext() -- get next available view object
		protected function viewGetNext() :int
		{
			// check for overflow
			if(m_numViews >= m_maxViews)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.viewGetNext(): " +
								"Maximum number of views exceeded");
				
				// stop here
				return(-1);
			}
			
			// verify context3D
			if(!m_context3DReady)
			{
				// throw error
				throw new Error("com.wb.software.WBEngine.viewGetNext(): " +
								"No render surface is available");
				
				// stop here
				return(-1);
			}
			
			// create arrays if needed
			if(!m_viewTexIdx)  m_viewTexIdx  = new Vector.<int>            (m_maxViews, true);
			if(!m_viewPosX)    m_viewPosX    = new Vector.<Number>         (m_maxViews, true);
			if(!m_viewPosY)    m_viewPosY    = new Vector.<Number>         (m_maxViews, true);
			if(!m_viewWidth)   m_viewWidth   = new Vector.<Number>         (m_maxViews, true);
			if(!m_viewHeight)  m_viewHeight  = new Vector.<Number>         (m_maxViews, true);
			if(!m_viewColor)   m_viewColor   = new Vector.<Vector.<Number>>(m_maxViews, true);
			if(!m_viewVisible) m_viewVisible = new Vector.<Boolean>        (m_maxViews, true);
			
			// init view data
			m_viewTexIdx [m_numViews] = -1;
			m_viewPosX   [m_numViews] = 0;
			m_viewPosY   [m_numViews] = 0;
			m_viewWidth  [m_numViews] = 0;
			m_viewHeight [m_numViews] = 0;
			m_viewColor  [m_numViews] = new <Number>[1, 1, 1, 1];
			m_viewVisible[m_numViews] = false;
			
			// return index & increment
			return(m_numViews++);
		}
		
		// viewGetPositionX() -- get x-position for view **time-critical
		protected function viewGetPositionX(idx :int) :Number
		{
			// return requested value
			return(m_viewPosX[idx]);
		}
		
		// viewGetPositionY() -- get y-position for view **time-critical
		protected function viewGetPositionY(idx :int) :Number
		{
			// return requested value
			return(m_viewPosY[idx]);
		}
		
		// viewGetWidth() -- get width for view **time-critical
		protected function viewGetWidth(idx :int) :Number
		{
			// return requested value
			return(m_viewWidth[idx]);
		}
		
		// viewInit() -- initialize views for rendering
		protected function viewInit() :void
		{
			// counters
			var c :int;

			// vertex shader program
			var vtxShader :String = "mul vt0, vc0, va0\n" + // scale to bounds size
									"add op,  vc1, vt0\n" + // translate to origin
									"mov v0,  va1\n";       // copy tex coords for fragment
			
			// vertex shader constants (dummy values to start)
			m_viewVtxConst = new <Number>[
				 2, -2, 0, 0,  // scale factor
				-1,  1, 0, 1]; // translation factor

			// pixel shader program
			var pxlShader :String = "tex ft0, v0,  fs0 <2d,clamp,linear>\n" + // apply texture map using stored coords
									"mul oc,  fc0, ft0\n";                    // apply shade color

			// pixel shader constants
			var pxlConst :Vector.<Number> = new <Number>[
				1, 1, 1, 1]; // shade color
			
			// vertices
			var vertices :Vector.<Number> = new Vector.<Number>;
			
			// set starting vertices
			for(c = 0; c < m_maxViews; c++)
			{
				// compute base
				var b :int = c * 16;
				
				// set vertices (x, y, u, v)
				vertices[b++] = 0; vertices[b++] = 0; vertices[b++] = 0; vertices[b++] = 0;
				vertices[b++] = 1; vertices[b++] = 0; vertices[b++] = 1; vertices[b++] = 0;
				vertices[b++] = 1; vertices[b++] = 1; vertices[b++] = 1; vertices[b++] = 1;
				vertices[b++] = 0; vertices[b++] = 1; vertices[b++] = 0; vertices[b++] = 1;
			}
  			
			// vertex buffer format
			var vtxBufFormat :Vector.<String> = new <String>[
				Context3DVertexBufferFormat.FLOAT_2,  // x, y
				Context3DVertexBufferFormat.FLOAT_2]; // u, v
			
			// indices
			var indices :Vector.<uint> = new Vector.<uint>;
			
			// set starting indices
			for(c = 0; c < m_maxViews; c++)
			{
				// compute bases
				var b1 :int = c * 6;
				var b2 :int = c * 4;
				
				// set indices
				indices[b1++] = b2 + 0;
				indices[b1++] = b2 + 1;
				indices[b1++] = b2 + 2;
				indices[b1++] = b2 + 2;
				indices[b1++] = b2 + 3;
				indices[b1++] = b2 + 0;
			}
			
			// add objects for views
			m_viewShader = shaderAdd(vtxShader, pxlShader, m_viewVtxConst, pxlConst);
			m_viewVtxBuf = vertexBufferAdd(vertices, vtxBufFormat, false);
			m_viewIdxBuf = indexBufferAdd(indices, false);
			
			// create texture & color lists
			m_viewTexList   = new Vector.<int>(m_maxViews, true);
			m_viewColorList = new Vector.<int>(m_maxViews, true);
		}
		
		// viewRender() -- render all visible views **time-critical
		protected function viewRender() :void
		{
			// counter
			var c :int;
			
			// check views
			if(m_numViews <= 0)
				return;
			
			// reset view counter
			var viewCount :int = 0;
			
			// reset buffer counters
			var i  :int = 0;
			var v1 :int = 0;
			var v2 :int = 0;
			
			// process visible views
			for(c = 0; c < m_numViews; c++)
				if(m_viewVisible[c])
				{
					// compute view coordinates
					var x1 :Number = m_worldX + m_viewPosX[c];
					var x2 :Number = x1 + m_viewWidth[c];
					var y1 :Number = m_worldY + m_viewPosY[c];
					var y2 :Number = y1 + m_viewHeight[c];

					// set vertices
					m_vtxBufVertices[m_viewVtxBuf][v1]      = x1;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 1]  = y1;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 4]  = x2;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 5]  = y1;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 8]  = x2;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 9]  = y2;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 12] = x1;
					m_vtxBufVertices[m_viewVtxBuf][v1 + 13] = y2;
					
					// set indices
					m_idxBufIndices[m_viewIdxBuf][i]     = v2;
					m_idxBufIndices[m_viewIdxBuf][i + 1] = v2 + 1;
					m_idxBufIndices[m_viewIdxBuf][i + 2] = v2 + 2;
					m_idxBufIndices[m_viewIdxBuf][i + 3] = v2 + 2;
					m_idxBufIndices[m_viewIdxBuf][i + 4] = v2 + 3;
					m_idxBufIndices[m_viewIdxBuf][i + 5] = v2;
					
					// add to texture & color list
					m_viewTexList  [viewCount] = m_viewTexIdx[c];
					m_viewColorList[viewCount] = c;
					
					// update counters
					viewCount++;
					i  += 6;
					v1 += 16;
					v2 += 4;
				}

			// re-upload buffers
			vertexBufferUpload(m_viewVtxBuf);
			indexBufferUpload (m_viewIdxBuf);
			
			// set render objects
			shaderSetCurrent      (m_viewShader);
			vertexBufferSetCurrent(m_viewVtxBuf);
			
			// apply new values to vertex constants
			m_viewVtxConst[0] = m_viewScaleX; 
			m_viewVtxConst[1] = m_viewScaleY; 
			m_viewVtxConst[4] = m_viewOfsX;
			m_viewVtxConst[5] = m_viewOfsY;
			
			// update vertex constants
			shaderUpdateVertexConstants(m_viewShader, m_viewVtxConst, 0, false);

			// set alpha-blend mode
			setBlendMode(BLEND_ALPHA);
			
			// reset index buffer counter
			i = 0;
			
			// render each view
			for(c = 0; c < viewCount; c++)
			{
				// set texture
				textureSetCurrent(m_viewTexList[c]);
				
				// set color
				shaderUpdatePixelConstants(m_viewShader,
										   m_viewColor[m_viewColorList[c]],
										   0,
										   false);
				
				// render view
				indexBufferRender(m_viewIdxBuf, i, 2);
				
				// update index buffer counter
				i += 6;
			}
		}
		
		// viewSaveBitmapData() -- re-upload a view's associated texture after edit **time-critical
		protected function viewSaveBitmapData(idx :int) :void
		{
			// reupload the texture
			textureUpload(m_viewTexIdx[idx]);
		}
		
		// viewSetAlpha() -- update alpha for view **time-critical
		protected function viewSetAlpha(idx   :int,
										alpha :Number) :void
		{
			// copy new color
			m_viewColor[idx][3] = alpha;
		}
		
		// viewSetBlue() -- update blue color for view **time-critical
		protected function viewSetBlue(idx   :int,
									   blue  :Number) :void
		{
			// copy new color component
			m_viewColor[idx][2] = blue;
		}
		
		// viewSetColor() -- update color for view **time-critical
		protected function viewSetColor(idx   :int,
										red   :Number,
										green :Number,
										blue  :Number,
										alpha :Number = 1.0) :void
		{
			// copy new color
			m_viewColor[idx][0] = red;
			m_viewColor[idx][1] = green;
			m_viewColor[idx][2] = blue;
			m_viewColor[idx][3] = alpha;
		}
		
		// viewSetGreen() -- update green color for view **time-critical
		protected function viewSetGreen(idx   :int,
										green :Number) :void
		{
			// copy new color component
			m_viewColor[idx][1] = green;
		}
		
		// viewSetInvisible() -- make view invisible **time-critical
		protected function viewSetInvisible(idx :int) :void
		{
			// clear visiblity flag
			m_viewVisible[idx] = false;
		}
		
		// viewSetRed() -- update red color for view **time-critical
		protected function viewSetRed(idx   :int,
									  red   :Number) :void
		{
			// copy new color component
			m_viewColor[idx][0] = red;
		}
		
		// viewSetPosition() -- set position for view **time-critical
		protected function viewSetPosition(idx :int,
										   x   :Number,
										   y   :Number) :void
		{
			// copy new position
			m_viewPosX[idx] = x;
			m_viewPosY[idx] = y;
		}
		
		// viewSetSize() -- set size for view **time-critical
		protected function viewSetSize(idx    :int,
									   width  :Number,
									   height :Number) :void
		{
			// copy new size
			m_viewWidth [idx] = width;
			m_viewHeight[idx] = height;
		}
		
		// viewSetTexture() -- set new texture for view **time-critical
		protected function viewSetTexture(vwIdx :int,
										  txIdx :int) :void
		{
			// set new texture index
			m_viewTexIdx[vwIdx] = txIdx;
		}
		
		// viewSetVisible() -- set visibility of view **time-critical
		protected function viewSetVisible(idx     :int,
									   	  visible :Boolean = true) :void
		{
			// copy visiblity flag
			m_viewVisible[idx] = visible;
		}
	}
}
