

Shader "Noise/ImprovedPerlinNoise2D" 
{
	Properties
	{
		 _PermTable1D ("permtable (RGB)", 2D) = "white" {}
		 _Gradient2D ("gradient (RGB)", 2D) = "white" {}
		_Off ("offset", float) = 1.0
	}
	
	SubShader 
	{
	    Pass 
	    {
	
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#include "UnityCG.cginc"
			
			uniform sampler2D _PermTable1D, _Gradient2D;
			uniform float _Frequency, _Lacunarity, _Gain, _Off;
			
			struct v2f 
			{
			    float4 pos : SV_POSITION;
			    float4 uv : TEXCOORD;
			};
			
			v2f vert (appdata_base v)
			{
			    v2f o;
			    o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			    o.uv = v.vertex;
			    return o;
			}
			
			float2 fade(float2 t)
			{
				return t * t * t * (t * (t * 6 - 15) + 10);
			}
			
			float perm(float x)
			{
				return tex2D(_PermTable1D, float2(x,0)).a;
			}
			
			float grad(float x, float2 p)
			{
				float2 g = tex2D(_Gradient2D, float2(x*8.0, 0) ).rg *2.0 - 1.0;
				return dot(g, p);
			}
						
			float inoise(float2 p)
			{
				float2 P = fmod(floor(p), 256.0);	// FIND UNIT SQUARE THAT CONTAINS POINT
			  	p -= floor(p);                      // FIND RELATIVE X,Y OF POINT IN SQUARE.
				float2 f = fade(p);                 // COMPUTE FADE CURVES FOR EACH OF X,Y.
			
				P = P / 256.0;
				const float one = 1.0 / 256.0;
				
			    // HASH COORDINATES OF THE 4 SQUARE CORNERS
			  	float A = perm(P.x) + P.y;
			  	float B = perm(P.x + one) + P.y;
			 
				// AND ADD BLENDED RESULTS FROM 4 CORNERS OF SQUARE
			  	return lerp( lerp( grad(perm(A    ), p ),  
			                       grad(perm(B    ), p + float2(-1, 0) ), f.x),
			                 lerp( grad(perm(A+one    ), p + float2(0, -1) ),
			                       grad(perm(B+one    ), p + float2(-1, -1) ), f.x), f.y);
			                           
			}
			
			// fractal sum, range -1.0 - 1.0
			float fBm(float2 p, int octaves)
			{
				float freq = _Frequency, amp = 0.5;
				float sum = 0;	
				for(int i = 0; i < octaves; i++) 
				{
					sum += inoise(p * freq) * amp;
					freq *= _Lacunarity;
					amp *= _Gain;
				}
				return sum;
			}
			
			// fractal abs sum, range 0.0 - 1.0
			float turbulence(float2 p, int octaves)
			{
				float sum = 0;
				float freq = _Frequency, amp = 1.0;
				for(int i = 0; i < octaves; i++) 
				{
					sum += abs(inoise(p*freq))*amp;
					freq *= _Lacunarity;
					amp *= _Gain;
				}
				return sum;
			}
			
			// Ridged multifractal, range 0.0 - 1.0
			// See "Texturing & Modeling, A Procedural Approach", Chapter 12
			float ridge(float h, float offset)
			{
			    h = abs(h);
			    h = offset - h;
			    h = h * h;
			    return h;
			}
			
			float ridgedmf(float2 p, int octaves, float offset)
			{
				float sum = 0;
				float freq = _Frequency, amp = 0.5;
				float prev = 1.0;
				for(int i = 0; i < octaves; i++) 
				{
					float n = ridge(inoise(p*freq), offset);
					sum += n*amp*prev;
					prev = n;
					freq *= _Lacunarity;
					amp *= _Gain;
				}
				return sum;
			}
			
			half4 frag (v2f i) : COLOR
			{
				//uncomment this for fractal noise
				//float n = fBm(i.uv.xz, 4);
				
				//uncomment this for turbulent noise
				float n = turbulence(i.uv.xz, 4);
				
				//uncomment this for ridged multi fractal
				//float n = ridgedmf(i.uv.xz, 4, _Off);
			
			    return half4(n,n,n,1);
			}
			
			ENDCG
	
	    }
	}
	Fallback "VertexLit"
}

