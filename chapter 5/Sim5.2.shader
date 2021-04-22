Shader "Custom/Sim5.2"{
   Properties{
     _Color ("Color Tint",Color) = (1.0,1.0,1.0,1.0)
   }

   SubShader {
      Pass {
         CGPROGRAM

         #pragma vertex vert
         #pragma fragment frag

         fixed4 _Color;

         struct a2v{
            float4 vertex : POSITION;
            float3 normal : NORMAL;
            float3 texcoord : TEXCOORD0;
         };

         struct v2f{
            float4 pos : SV_POSITION;
            fixed3 Color : COLOR0;
         };

         v2f vert (a2v v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.Color = v.normal*0.5 + fixed3(0.5,0.5,0.5);
            return o;
         };

         fixed4 frag (v2f i) : SV_TARGET{
            fixed3 c = i.Color;
            c *=  _Color.rgb;
            return fixed4(c,1.0);
         };
          
         ENDCG
      } 
   }
}

