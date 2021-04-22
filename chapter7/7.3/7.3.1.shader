Shader "Unlit/7.3.1"
{
    Properties{
        //控制面板控制的元素，声明属性，定义初始值
        _Color("Color Tint",Color) = (1,1,1,1)
        _Ramptex("Ramp Tex",2D) = "white"{}
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",range(2,255)) = 10
    }
    
    SubShader{
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            //定义与类型相匹配的变量，以便properties能使用
            fixed4 _Color;
            sampler2D _Ramptex;
            float4 _Ramptex_ST;
            fixed4 _Specular;
            float _Gloss;

            //定义输入输出结结构
            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                float4 texcoord :TEXCOORD0;
            };
            struct v2f{
                float4 pos :POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                float2 uv :TEXCOORD2;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord,_Ramptex);
                //了内置的 TRANSFORM TEX 宏来计算经过平铺和偏移后的纹理坐标。
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //使用haltLambert构建一个纹理坐标，并用这个纹理坐标对渐变纹理 RampTex 进行采样。
                fixed halfLambert = 0.5*dot(worldNormal,worldLightDir) + 0.5;
                //tex2d是纹理采样  应该是tex2d（采样的图，i.uv）.rgb
                //这里于 RampTex 实际就是一个一维纹理（它在纵轴方向上颜色不变） 纹理坐标的u.v方向我们都使用了 halfLambert 。
                fixed3 diffuseColor = tex2D(_Ramptex,fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular * pow( max( 0,dot(worldNormal,halfDir)),_Gloss);

                return fixed4 (diffuse + specular + ambient,1.0);
                
            }
            ENDCG
        }
    }Fallback "Specular"
}