Shader "Custom/caps 6.4.2"
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
                o.pos = UnityObjectToClipPos(v.vertex) ;                              
                o.worldNormal = mul( v.normal, (float3x3)unity_WorldToObject ) ;                
                return o;
            }

            //片元着色器需要计算漫反射光照模型
            fixed4 frag (v2f i):SV_TARGET {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;                
                fixed3 worldNormal = normalize( i.worldNormal ); 
                fixed3 WorldSpaceLightDir = normalize( _WorldSpaceLightPos0.xyz );
                fixed3 diffuse = _LightColor0.rgb  * _Diffuse.rgb * saturate(dot(worldNormal,WorldSpaceLightDir));                
                fixed3 color = diffuse + ambient;
                return fixed4( color,1.0 );
            }            
            
            ENDCG

        }
    }

    Fallback "Diffuse"
    //Fallback在subshader后面
}

//总结：逐像素光照可以得到更加平滑的光照效果。
//但是，即便使用了逐像素漫反射光照，有个问题仍然存在。在光照无法到达的区域 模型的外观通常是全黑的，没有任何明暗变化，这会使模背光区域看起来就像一个平面一样，失去了模型细节表现。
//解决办法：实际上我们可以通过添加环境光来得到非全黑的效果，但即便这样仍然无法解决背光面明暗一样的缺点。为此 有一种改善技术被提出来，这就是半兰伯特 (Half Lambert) 光照模型