package starling.display.graphicsEx
{
	import starling.display.DisplayObjectContainer;
	import starling.display.Graphics;
	import starling.display.graphics.Stroke;
	import starling.display.graphics.StrokeVertex;

	public class GraphicsEx extends Graphics
	{
		protected var _currentStrokeEx:StrokeEx;
		
		public function GraphicsEx(displayObjectContainer:DisplayObjectContainer)
		{
			super(displayObjectContainer);
		}

		override protected function clearCurrentStroke() : void
		{
			super.clearCurrentStroke();
			
			_currentStrokeEx = null;
		}
		
		public function get currentLineIndex() : int
		{
			if ( _currentStroke != null )
				return _currentStroke.numVertices;
			else
				return 0;
		}

		public function currentLineLength() : Number
		{
			if ( _currentStrokeEx )
				return _currentStrokeEx.strokeLength();
			else
				return 0;
		}
		
		/**
		 * performs the natural cubic slipne transformation
		 * @param	controlPoints a Vector.<Point> of the control points
		 * @param	closed a boolean to tell wether the curve is opened or closed
		 * @param   steps - an int indicating the number of steps between control points
		 */

		public function naturalCubicSplineTo( controlPoints:Array, closed:Boolean, steps:int = 4) : void
		{
			var i:int = 0;
			var j:Number = 0;

			var numPoints:int = controlPoints.length;
			var xpoints:Vector.<Number> = new Vector.<Number>(numPoints, true);
			var ypoints:Vector.<Number> = new Vector.<Number>(numPoints, true);

			for ( i = 0; i < controlPoints.length; i++ )
			{
				xpoints[i] = controlPoints[ i ].x ;
				ypoints[i] = controlPoints[ i ].y ;
			}

			var X:Vector.<Cubic>;
			var Y:Vector.<Cubic>;

			if ( closed )
			{
				X = calcClosedNaturalCubic(	numPoints-1, xpoints );
				Y = calcClosedNaturalCubic(	numPoints-1, ypoints );
			}
			else
			{
				X = calcNaturalCubic(	numPoints - 1, xpoints );
				Y = calcNaturalCubic(	numPoints - 1, ypoints );
			}


			/* very crude technique - just break each segment up into _steps lines */
			var points:Vector.<Number> = new Vector.<Number>(2*steps, true);

			var invSteps:Number = 1.0 / steps;
			for ( i = 0; i < X.length; i++)
			{
				for ( j = 0; j < steps; j++)
				{
					var u:Number = j * invSteps;
					var valueX:Number = X[i].eval(u);
					var valueY:Number = Y[i].eval(u);
					points[j*2  ] = valueX;
					points[j*2+1] = valueY;
				}
				
				drawPointsInternal(points);
			}
		}

		public function postProcess(startIndex:int, endIndex:int, thicknessData:GraphicsExThicknessData = null, colorData:GraphicsExColorData = null ) : Boolean
		{
			if ( _currentStrokeEx == null)
				return false;
			
			var verts:Vector.<StrokeVertex> = _currentStrokeEx.strokeVertices;
			var totalVerts:int = _currentStrokeEx.numVertices;						
			if ( startIndex >= totalVerts || startIndex < 0 )
				return false;
			if ( endIndex >= totalVerts || endIndex < 0 )
				return false;	
			if ( startIndex == endIndex )
				return false;
			
			var numVerts:int = endIndex - startIndex;
			if ( colorData )
			{
				if ( thicknessData )
				{
					postProcessThicknessColorInternal(numVerts, startIndex, endIndex, verts, thicknessData, colorData);
				}
				else
				{
					postProcessColorInternal(numVerts, startIndex, endIndex, verts, colorData);
				}
			}
			else
			{
				if ( thicknessData )
				{
					postProcessThicknessInternal(numVerts, startIndex, endIndex, verts, thicknessData);
				}
			}
			_currentStrokeEx.invalidate();
			return true;
		}
		
		private function postProcessThicknessColorInternal(numVerts:int, startIndex:int, endIndex:int, verts:Vector.<StrokeVertex> , thicknessData:GraphicsExThicknessData, colorData:GraphicsExColorData ):void 
		{
			numVerts = endIndex - startIndex;
			var invNumVerts:Number = 1.0 / Number(numVerts);
			var lerp:Number = 0;	
			var inv255:Number = 1.0 / 255.0;
			
			var t:Number; // thickness
			var r:Number;
			var g:Number;
			var b:Number;
			var a:Number;
			var i:Number;
			
			for ( i= startIndex; i <= endIndex ; ++i )
			{
				t= (thicknessData.startThickness * (1.0 - lerp)) + thicknessData.endThickness * lerp;
				
				r= inv255 * ((colorData.startRed * (1.0 - lerp)) + colorData.endRed * lerp);
				g= inv255 * ((colorData.startGreen * (1.0 - lerp)) + colorData.endGreen * lerp);
				b= inv255 * ((colorData.startBlue * (1.0 - lerp)) + colorData.endBlue* lerp);
				a= ((colorData.startAlpha * (1.0 - lerp)) + colorData.endAlpha* lerp);
				
				verts[i].thickness = t;
				
				verts[i].r1 = r;
				verts[i].r2 = r;
				verts[i].g1 = g;
				verts[i].g2 = g;
				verts[i].b1 = b;
				verts[i].b2 = b;
				verts[i].a1 = a;
				verts[i].a2 = a;
				
				lerp += invNumVerts;
			}
		}

		private function postProcessColorInternal(numVerts:int, startIndex:int, endIndex:int, verts:Vector.<StrokeVertex> , colorData:GraphicsExColorData ):void 
		{
			var invNumVerts:Number = 1.0 / Number(numVerts);
			var lerp:Number = 0;	
			var inv255:Number = 1.0 / 255.0;
		
			var r:Number;
			var g:Number;
			var b:Number;
			var a:Number;
			
			var i:Number;
			
			for ( i= startIndex; i <= endIndex ; ++i )
			{
				r= inv255 * ((colorData.startRed * (1.0 - lerp)) + colorData.endRed * lerp);
				g= inv255 * ((colorData.startGreen * (1.0 - lerp)) + colorData.endGreen * lerp);
				b= inv255 * ((colorData.startBlue * (1.0 - lerp)) + colorData.endBlue* lerp);
				a= ((colorData.startAlpha * (1.0 - lerp)) + colorData.endAlpha* lerp);
				
				verts[i].r1 = r;
				verts[i].r2 = r;
				verts[i].g1 = g;
				verts[i].g2 = g;
				verts[i].b1 = b;
				verts[i].b2 = b;
				verts[i].a1 = a;
				verts[i].a2 = a;
				
				lerp += invNumVerts;
			}
		}

		protected function postProcessThicknessInternal(numVerts:int, startIndex:int, endIndex:int, verts:Vector.<StrokeVertex> , thicknessData:GraphicsExThicknessData ):void 
		{
			numVerts = endIndex - startIndex;
			var invNumVerts:Number = 1.0 / Number(numVerts);
			var lerp:Number = 0;	
			var inv255:Number = 1.0 / 255.0;
			
			var t:Number; // thickness
			var i:Number;
			
			for ( i= startIndex; i <= endIndex ; ++i )
			{
				t = (thicknessData.startThickness * (1.0 - lerp)) + thicknessData.endThickness * lerp;
				verts[i].thickness = t;
				lerp += invNumVerts;
			}
		}

		override protected function createStroke() : Stroke
		{ // Created to be able to extend class with different strokes for different folks.
			_currentStrokeEx = new StrokeEx();
			
			return _currentStrokeEx as Stroke;
		}
		

		
		protected function drawPointsInternal(points:Vector.<Number>) : void
		{
			var L:int = points.length;
			if ( L > 0 )
			{
				var invHalfL:Number = 1.0/(0.5*L);
				for ( var i:int = 0; i < L; i+=2 )
				{
					var x:Number = points[i];
					var y:Number = points[i+1];

					if ( i == 0 && isNaN(_currentX) )
					{
						moveTo( x, y );
					}
					else
					{
						lineTo(x, y);
					}
				}
			}
		}

	

		private function calcNaturalCubic( n:int, x:Vector.<Number> ) :Vector.<Cubic>
		{
			var i:int;
			var gamma:Vector.<Number> = new Vector.<Number>( n + 1 );;
			var delta:Vector.<Number> = new Vector.<Number>( n + 1 );
			var D:Vector.<Number> = new Vector.<Number>( n+1 );

			gamma[0] = 1.0/2.0;
			for ( i = 1; i < n; i++)
			{
				gamma[i] = 1 / (4 - gamma[i - 1]);
			}
			gamma[n] = 1 / (2 - gamma[n - 1]);

			delta[0] = 3 * (x[1] - x[0]) * gamma[0];


			for ( i = 1; i < n; i++)
			{
				delta[i] = (3 * (x[i + 1] - x[i - 1]) - delta[i - 1]) * gamma[i];
			}
			delta[n] = (3 * (x[n] - x[n - 1]) - delta[n - 1]) * gamma[n];


			D[n] = delta[n];

			for ( i = n - 1; i >= 0; i--)
			{

				D[i] = delta[i] - gamma[i] * D[i + 1];

			}

			/* now compute the coefficients of the cubics */
			var C:Vector.<Cubic> = new Vector.<Cubic>( n );

			for ( i = 0; i < n; i++)
			{
				C[i] = new Cubic(
						x[i],
						D[i],
						3 * (x[i + 1] - x[i]) - 2 * D[i] - D[i + 1],
						2 * (x[i] - x[i + 1]) + D[i] + D[i + 1]
				);
			}
			return C;
		}



		private function calcClosedNaturalCubic( n:int, x:Vector.<Number>):Vector.<Cubic>
		{

			var w:Vector.<Number> = new Vector.<Number>( n+1 );
			var v:Vector.<Number> = new Vector.<Number>( n+1 );
			var y:Vector.<Number> = new Vector.<Number>( n+1 );
			var D:Vector.<Number> = new Vector.<Number>( n+1 );
			var z:Number, F:Number, G:Number, H:Number;
			var k:int;

			w[1] = v[1] = z = 1 / 4;
			y[0] = z * 3 * (x[1] - x[n]);
			H = 4;
			F = 3 * (x[0] - x[n - 1]);
			G = 1;
			for ( k = 1; k < n; k++)
			{

				v[k + 1] = z = 1 / (4 - v[k]);
				w[k + 1] = -z * w[k];
				y[k] = z * (3 * (x[k + 1] - x[k - 1]) - y[k - 1]);
				H = H - G * w[k];
				F = F - G * y[k - 1];
				G = -v[k] * G;

			}
			H = H - (G + 1) * (v[n] + w[n]);
			y[n] = F - (G + 1) * y[n - 1];


			D[n] = y[n] / H;

			/* This equation is WRONG! in my copy of Spath */
			D[n - 1] = y[n - 1] - (v[n] + w[n]) * D[n];
			for ( k = n - 2; k >= 0; k--)
			{
				D[k] = y[k] - v[k + 1] * D[k + 1] - w[k + 1] * D[n];
			}


			/* now compute the coefficients of the cubics */
			var C:Vector.<Cubic> = new Vector.<Cubic>( n+1 );
			for ( k = 0; k < n; k++)
			{
				C[k] = new Cubic(
						x[k],
						D[k],
						3 * (x[k + 1] - x[k]) - 2 * D[k] - D[k + 1],
						2 * (x[k] - x[k + 1]) + D[k] + D[k + 1]
				);

			}
			C[n] = new Cubic(
					x[n],
					D[n],
					3 * (x[0] - x[n]) - 2 * D[n] - D[0],
					2 * (x[n] - x[0]) + D[n] + D[0]
			);
			return C;
		}
		
		


	}

}

class Cubic
{
	/** this class represents a cubic polynomial */
	private var a:Number,b:Number,c:Number,d:Number;         /* a + b*u + c*u^2 +d*u^3 */

	public function Cubic(a:Number, b:Number, c:Number, d:Number)
	{
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
	}

	/** evaluate cubic */
	public function eval( u:Number ):Number
	{

		return (((d * u) + c) * u + b) * u + a;

	}
}

