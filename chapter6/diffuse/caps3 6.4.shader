Shader "Custom/caps 6.4.3"
{
    Properties{
        _Diffuse("Diffuse",Color) = (1.0,1.0,1.0,1.0)
    }

    SubShader{
        pass{
            Tags{"LightMode" = "ForwardBase"}
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Diffuse; 

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
            };

            //顶点着色器不需要计算光照模型，只需要把世界空间下的法线传递给片元着色器即可：
            v2f vert (a2v v ){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);                              
                o.worldNormal = mul( v.normal, (float3x3)unity_WorldToObject ) ;                
                return o;
            }

            //片元着色器需要计算漫反射光照模型
            fixed4 frag (v2f i):SV_TARGET {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;                
                fixed3 worldNormal = normalize( i.worldNormal ); 
                fixed3 WorldSpaceLightDir = normalize( _WorldSpaceLightPos0.xyz );
                //计算公式变了
                fixed halfLambert = dot(worldNormal,WorldSpaceLightDir)*0.5+0.5;
                fixed3 diffuse = _LightColor0.rgb  * _Diffuse.rgb * halfLambert;               
                
                fixed3 color = diffuse + ambient;
                return fixed4( color,1.0 );
            }            
            
            ENDCG

        }
    }

    Fallback "Diffuse"
    //Fallback在subshader后面
}