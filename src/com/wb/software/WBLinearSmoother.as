/******************************************************************************/
/*                                                                            */
/*  WBLinearSmoother -- class for giving more natural movement to otherwise   */
/*                      hard linear motions.                                  */
/*                                                                            */
/*  Two types of curve calculations:                                          */
/*                                                                            */
/*    SIMPLE  -- one curve is calculated using incoming & ougoing slopes      */
/*    COMPLEX -- two curves are calculated, one from incoming to center       */
/*                 and one from center to outgoing                            */
/*                                                                            */
/*  Both types provide the ability to bounce into place at the end.  A        */
/*  "bounce factor" value is used to control the intensity of this bounce.    */
/*                                                                            */
/*  Use LMSMOOTH.BAS and LMSMOTH2.BAS to experiment and find the desired      */
/*  values for the above variables.                                           */
/*                                                                            */
/*  Values are interpolated in the following ways:                            */
/*    < -2.0       -- undefined                                               */
/*    -2.0 to -1.0 -- incoming bounce                                         */
/*    -1.0 to 0.0  -- incoming curve                                          */
/*    0.0 to 1.0   -- outgoing curve                                          */
/*    1.0 to 2.0   -- outgoing bounce                                         */
/*    > 2.0        -- undefined                                               */
/*                                                                            */
/*  The following mathematical restrictions exist on SIMPLE curves:           */
/*    IN cannot be 0, OUT cannot be 0                                         */
/*    IN and OUT cannot be equal                                              */
/*    IN cannot be negative                                                   */
/*    if IN > 1 then OUT must be < 1                                          */
/*    if IN < 1 then OUT must be > 1                                          */
/*                                                                            */
/*  The following mathematical restrictions exist on COMPLEX curves:          */
/*    IN cannot be 0, CEN cannot be 0, OUT cannot be 0                        */
/*    IN and CEN cannot be equal                                              */
/*    OUT and CEN cannot be equal                                             */
/*    CEN cannot be negative                                                  */
//    if IN > 1 then OUT must be > 1 and CEN must be < 1                      */
//    if IN < 1 then OUT must be < 1 and CEN must be > 1                      */
/*                                                                            */
/*  Smoothers can use a pre-calculated lookup table.  When using a lookup     */
/*  table, the update option can be used in conjunction wit the app's         */
/*  per-frame update.  Several smoothers can be chained to update together.   */
/*  Modifying or re-factoring any link in the chain will unchain the rest.    */
/*                                                                            */
/*  For the sake of exeuction speed, NO ERROR CHECKING is performed in        */
/*  time-critical methods, so use with caution!                               */
/*                                                                            */
/******************************************************************************/
package com.wb.software
{
	internal class WBLinearSmoother
	{
		// smoother type
		private var m_smootherType :int = 0;
		
		// calculation values
		private var mL   :Number = 0.0;
		private var mC   :Number = 0.0;
		private var mR   :Number = 0.0;
		private var numB :Number = 0.0;
		private var xL   :Number = 0.0;
		private var yL   :Number = 0.0;
		private var xA   :Number = 0.0;
		private var yA   :Number = 0.0;
		private var xR   :Number = 0.0;
		private var yR   :Number = 0.0;
		private var amL  :Number = 0.0;
		private var axL  :Number = 0.0;
		private var ayL  :Number = 0.0;
		private var amR  :Number = 0.0;
		private var axR  :Number = 0.0;
		private var ayR  :Number = 0.0;
		
		// range values
		private var m_rangeMin :Number = 0.0;
		private var m_rangeCen :Number = 0.0;
		private var m_rangeMax :Number = 0.0;
		private var m_rangeOfs :Number = 0.0;
		
		// lookup table data
		private var m_lookupTable   :Vector.<Number> = null;
		private var m_lookupCurrent :int             = 0;
		private var m_lookupDelta   :int             = 0;
		private var m_lookupMax     :int             = 0;
		private var m_lookupStopped :Boolean         = false;
		
		// chained objects
		private var m_chainedObj :WBLinearSmoother = null;

		// type flags
		public const TYPE_LINEAR  :int = 0;
		public const TYPE_SIMPLE  :int = 1;
		public const TYPE_COMPLEX :int = 2;
		
		// default constructor
		public function WBLinearSmoother(smootherType  :int    = TYPE_LINEAR,
										 incomingSlope :Number = 0.0,
										 centerSlope   :Number = 0.0,
										 outgoingSlope :Number = 0.0,
										 bounceFactor  :Number = 0.0,
										 rangeMin      :Number = 0.0,
										 rangeMax      :Number = 0.0)
		{
			// refactor based on curve type
			switch(smootherType)
			{
			// simple curve
			case(TYPE_SIMPLE):
				
				// refactor as simple
				refactorSimple(incomingSlope,
							   outgoingSlope,
							   bounceFactor);
				
				// ok
				break;
			
			// complex curve
			case(TYPE_COMPLEX):
				
				// refactor as complex
				refactorComplex(incomingSlope,
								centerSlope,
								outgoingSlope,
								bounceFactor);
				
				// ok
				break;
			
			// undefined or linear
			default:
				
				// refactor as undefined
				refactorUndefined();
				
				// ok
				break;
			}
			
			// set range
			setRange(rangeMin, rangeMax);
		}
		
		// calculate() -- compute smoothed value for a given point
		public function calculate(x :Number) :Number
		{
			// return value
			var y :Number;
			
			// working values
			var x1 :Number;
			var y1 :Number;
			var x2 :Number;
			var y2 :Number;
			var f  :Number;
			var xp :Number;
			
			// calculate based on curve type
			switch(m_smootherType)
			{
			// simple curve
			case(TYPE_SIMPLE):
				
				// compute based on position of x (sorry, no comments!)
				if(x < -1)
				{
					f  = -(x + 1);
					x1 = ((axL + 1) * f) - 1;
					y1 = ((ayL + 1) * f) - 1;
					x2 = ((-2 - axL) * f) + axL;
					y2 = ((-1 - ayL) * f) + ayL;
					f  = ((x - x1) / (x2 - x1));
					y  = ((y2 - y1) * f) + y1;
					xp = (x + 1);
					y  = ((y + 1) * Math.cos(xp * xp * numB * Math.PI) * (1 - f)) - 1;
				}
				else if(x > 1)
				{
					f  = (x - 1);
					x1 = ((axR - 1) * f) + 1;
					y1 = ((ayR - 1) * f) + 1;
					x2 = ((2 - axR) * f) + axR;
					y2 = ((1 - ayR) * f) + ayR;
					f  = ((x - x1) / (x2 - x1));
					y  = ((y2 - y1) * f) + y1;
					xp = (x - 1);
					y  = ((y - 1) * Math.cos(xp * xp * numB * Math.PI) * (1 - f)) + 1;
				}
				else
				{
					f  = (x + 1) / 2;
					x1 = ((xA + 1) * f) - 1;
					y1 = ((yA + 1) * f) - 1;
					x2 = ((1 - xA) * f) + xA;
					y2 = ((1 - yA) * f) + yA;
					f  = (x - x1) / (x2 - x1);
					y  = ((y2 - y1) * f) + y1;
				}
				
				// ok
				break;
			
			// complex curve
			case(TYPE_COMPLEX):
				
				// compute based on position of x (sorry, no comments!)
				if(x < -1)
				{
					f  = -(x + 1);
					x1 = ((axL + 1) * f) - 1;
					y1 = ((ayL + 1) * f) - 1;
					x2 = ((-2 - axL) * f) + axL;
					y2 = ((-1 - ayL) * f) + ayL;
					f  = ((x - x1) / (x2 - x1));
					y  = ((y2 - y1) * f) + y1;
					xp = (x + 1);
					y  = ((y + 1) * Math.cos(xp * xp * numB * Math.PI) * (1 - f)) - 1;
				}
				else if(x < -0.000001)
				{
					f  = (x + 1);
					x1 = ((xL + 1) * f) - 1;
					y1 = ((yL + 1) * f) - 1;
					x2 = (-xL * f) + xL;
					y2 = (-yL * f) + yL;
					f  = (x - x1) / (x2 - x1);
					y  = ((y2 - y1) * f) + y1;
				}
				else if(x > 1)
				{
					f  = (x - 1);
					x1 = ((axR - 1) * f) + 1;
					y1 = ((ayR - 1) * f) + 1;
					x2 = ((2 - axR) * f) + axR;
					y2 = ((1 - ayR) * f) + ayR;
					f  = ((x - x1) / (x2 - x1));
					y  = ((y2 - y1) * f) + y1;
					xp = (x - 1);
					y  = ((y - 1) * Math.cos(xp * xp * numB * Math.PI) * (1 - f)) + 1;
				}
				else if(x > 0.000001)
				{
					x1 = xR * x;
					y1 = yR * x;
					x2 = ((1 - xR) * x) + xR;
					y2 = ((1 - yR) * x) + yR;
					f  = (x - x1) / (x2 - x1);
					y  = ((y2 - y1) * f) + y1;
				}
				else
				{
					y = x;
				}

				// ok
				break;
			
			// undefined or linear
			default:
				
				// treat as linear
				if      (x < -1) y = -1.0;
				else if (x >  1) y =  1.0;
				else             y =  x;
			
				// ok
				break;
			}
			
			// return computed value
			return(y);
		}
		
		// calculateRanged() -- compute smoothed ranged value for a given point
		public function calculateRanged(x :Number) :Number
		{
			// get smoothed value
			var y :Number = calculate(x);
			
			// return ranged value
			return(m_rangeCen + (y * m_rangeOfs));
		}
		
		// chain() -- chain to another smoother for updating
		public function chain(chainedObj :WBLinearSmoother) :void
		{
			// add to existing chain or store locally
			if(m_chainedObj)
				m_chainedObj.chain(chainedObj);
			else
				m_chainedObj = chainedObj;
		}
		
		// chainLookupCreate() -- create floating point lookup table (chained)
		public function chainLookupCreate(totalSteps    :int,
									 	  startingFloat :Number  = -1.0,
									 	  endingFloat   :Number  =  1.0,
									 	  updateSpeed   :int     =  1,
									 	  startAtEnd    :Boolean =  false,
									 	  useRange      :Boolean =  false) :void
		{
			// process linked objects
			if(m_chainedObj)
				m_chainedObj.chainLookupCreate(totalSteps,
											   startingFloat,
											   endingFloat,
											   updateSpeed,
											   startAtEnd,
											   useRange);
			
			// process this object
			lookupCreate(totalSteps,
						 startingFloat,
						 endingFloat,
						 updateSpeed,
						 startAtEnd,
						 useRange);
		}
		
		// chainLookupCreateRanged() -- create ranged lookup table (chained)
		public function chainLookupCreateRanged(totalSteps    :int,
										   		startingFloat :Number  = -1.0,
										   		endingFloat   :Number  =  1.0,
										   		updateSpeed   :int     =  1,
										   		startAtEnd    :Boolean =  false) :void
		{
			// process linked objects
			if(m_chainedObj)
				m_chainedObj.chainLookupCreateRanged(totalSteps,
													 startingFloat,
													 endingFloat,
													 updateSpeed,
													 startAtEnd);
			
			// process this object
			lookupCreateRanged(totalSteps,
							   startingFloat,
							   endingFloat,
							   updateSpeed,
							   startAtEnd);
		}

		// chainRefactorComplex() -- refactor as complex curve (chained)
		public function chainRefactorComplex(incomingSlope :Number,
											 centerSlope   :Number,
											 outgoingSlope :Number,
											 bounceFactor  :Number = 0.0) :void
		{
			// process linked objects
			if(m_chainedObj)
				m_chainedObj.chainRefactorComplex(incomingSlope,
												  centerSlope,
												  outgoingSlope,
												  bounceFactor);
				
			// process this object
			refactorComplex(incomingSlope,
							centerSlope,
							outgoingSlope,
							bounceFactor);
		}
		
		// chainRefactorSimple() -- refactor as simple curve (chained)
		public function chainRefactorSimple(incomingSlope :Number,
											outgoingSlope :Number,
											bounceFactor  :Number = 0.0) :void
		{
			// process linked objects
			if(m_chainedObj)
				m_chainedObj.chainRefactorSimple(incomingSlope,
												 outgoingSlope,
												 bounceFactor);
			
			// process this object
			refactorSimple(incomingSlope,
						   outgoingSlope,
						   bounceFactor);
		}
		
		// chainRefactorUndefined() -- refactor as undefined (chained)
		public function chainRefactorUndefined() :void
		{
			// process linked objects
			if(m_chainedObj)
				m_chainedObj.chainRefactorUndefined();

			// process this object
			refactorUndefined();
		}
		
		// chainUpdate() -- update lookup table counter (chained) **time-critical
		public function chainUpdate() :void
		{
			// update linked objects
			if(m_chainedObj)
				m_chainedObj.chainUpdate();
			
			// update this object
			update();
		}
		
		// lookupCreate() -- create lookup table using floating point values
		public function lookupCreate(totalSteps    :int,
									 startingFloat :Number  = -1.0,
									 endingFloat   :Number  =  1.0,
									 updateSpeed   :int     =  1,
									 startAtEnd    :Boolean =  false,
									 useRange      :Boolean =  false) :void
		{
			// counter
			var c :int;
			
			// create lookup table array
			m_lookupTable = new Vector.<Number>(totalSteps, true);
			
			// set max value
			m_lookupMax = (totalSteps - 1);
			
			// fill in values
			for(c = 0; c <= m_lookupMax; c++)
			{
				// compute interpolation
				var f :Number = (c as Number) / (m_lookupMax as Number);
				
				// compute float value
				var x :Number = startingFloat + (f * (endingFloat - startingFloat));
				
				// check flag & add calculated value
				if(useRange)
					m_lookupTable[c] = calculateRanged(x);
				else
					m_lookupTable[c] = calculate(x);
			}
			
			// check direction
			if(startAtEnd)
			{
				// set start & delta
				m_lookupCurrent =  m_lookupMax;
				m_lookupDelta   = -updateSpeed;
			}
			else
			{
				// set start & delta
				m_lookupCurrent = 0;
				m_lookupDelta   = updateSpeed;
			}
			
			// reset stopped flag		
			m_lookupStopped = false;
		}
		
		// lookupCreateRanged() -- create lookup table using ranged values
		public function lookupCreateRanged(totalSteps    :int,
										   startingFloat :Number  = -1.0,
										   endingFloat   :Number  =  1.0,
										   updateSpeed   :int     =  1,
										   startAtEnd    :Boolean =  false) :void
		{
			// pass to other function with range flag set
			lookupCreate(totalSteps,
						 startingFloat,
						 endingFloat,
						 updateSpeed,
						 startAtEnd,
						 true);
		}
		
		// lookupCurrentValue() -- get current value in lookup table **time-critical
		public function lookupCurrentValue() :Number
		{
			// return requested value
			return(m_lookupTable[m_lookupCurrent]);
		}
	
		// lookupGetValue() -- get specific value from lookup table **time-critical
		public function lookupGetValue(value :int) :Number
		{
			// return requested value
			return(m_lookupTable[value]);
		}
		
		// refactorComplex() -- refactor as complex curve
		public function refactorComplex(incomingSlope :Number,
										centerSlope   :Number,
										outgoingSlope :Number,
										bounceFactor  :Number = 0.0) :void
		{
			// set type
			m_smootherType = TYPE_COMPLEX;
			
			// store input values
			mL   = incomingSlope;
			mC   = centerSlope;
			mR   = outgoingSlope;
			numB = bounceFactor;
			
			// compute working values
			xL   = (mL - 1) / (mC - mL);
			yL   = (mC * xL);
			xR   = (1 - mR) / (mC - mR);
			yR   = (mC * xR);
			amL  = (-1 / mL);
			axL  = (mL - (2 * amL)) / (amL - mL); 
			ayL  = ((amL * axL) + (2 * amL)) - 1;
			amR  = (-1 / mR);
			axR  = ((2 * amR) - mR) / (amR - mR);
			ayR  = ((amR * axR) - (2 * amR)) + 1;
		}
		
		// refactorSimple() -- refactor as simple curve
		public function refactorSimple(incomingSlope :Number,
									   outgoingSlope :Number,
									   bounceFactor  :Number = 0.0) :void
		{
			// set type
			m_smootherType = TYPE_SIMPLE;
			
			// store input values
			mL   = incomingSlope;
			mR   = outgoingSlope;
			numB = bounceFactor;
			
			// compute working values
			xA   = ((2 - mL) - mR) / (mL - mR);
			yA   = (mL * (xA + 1)) - 1; 
			amL  = (-1 / mL); 
			axL  = (mL - (2 * amL)) / (amL - mL); 
			ayL  = ((amL * axL) + (2 * amL)) - 1; 
			amR  = (-1 / mR);
			axR  = ((2 * amR) - mR) / (amR - mR);
			ayR  = ((amR * axR) - (2 * amR)) + 1; 
		}
		
		// refactorUndefined() -- refactor as undefined/linear
		public function refactorUndefined() :void
		{
			// set linear type
			m_smootherType = TYPE_LINEAR;
		}
		
		// setRange() -- store & compute useful range values
		public function setRange(rangeMin :Number,
								 rangeMax :Number) :void
		{
			// save min/max
			m_rangeMin = rangeMin;
			m_rangeMax = rangeMax;
			
			// compute center
			m_rangeCen = (rangeMin + rangeMax) / 2;
			
			// compute offset
			m_rangeOfs = (rangeMax - rangeMin) / 2;
		}
		
		// stopped() -- determine if cycle has reached its end **time-critical
		public function stopped() :Boolean
		{
			// return flag
			return(m_lookupStopped);
		}
		
		// unchain() -- remove all chained objects beyond this link
		public function unchain() :void
		{
			// unchain linked objects
			if(m_chainedObj)
				m_chainedObj.unchain();
			
			// release local object
			m_chainedObj = null;
		}
		
		// update() -- update lookup table counter **time-critical
		public function update() :void
		{
			// update current position
			m_lookupCurrent += m_lookupDelta;
			
			// check for underflow
			if(m_lookupCurrent < 0)
			{
				// clip value & set flag
				m_lookupCurrent = 0;
				m_lookupStopped = true;
			}
			
			// check for overflow
			if(m_lookupCurrent > m_lookupMax)
			{
				// clip value & set flag
				m_lookupCurrent = m_lookupMax;
				m_lookupStopped = true;
			}
		}
	}
}