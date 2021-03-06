// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/caps6.5.3"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1.0,1.0,1.0,1.0)
        _Specular("Specular",Color) = (1.0,1.0,1.0,1.0)
        //_Specular用于控制材质的高光反射颜色
        _Gloss("Gloss",Range(8.0,256)) = 20
        //_Gloss用于控制高光区域的大小
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            //为了在 Shader 中使 Properties 语义块中声明的属性，需要定义和这些属性类型相匹配的变量
            fixed4 _Diffuse;
            fixed4 _Specular;
            float  _Gloss;
            //Gloss 的范围很大，因此我们使用 float 度来存储。

            struct a2f
            {
                float4 vertex : POSITION;
                fixed3 normal  : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                fixed3 worldPos : TEXCOORD1;
            };


            //只传递一些参数,不计算
            v2f vert (a2f v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                //可以直接用unity内置函数写
                //o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                
                              
                return o;
            }

            //负责计算漫反射和高光反射部分
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize( _WorldSpaceLightPos0.xyz );
                //可以直接用unity内置函数写
                //fixed3 worldLightDir = normalize (UnityWorldSpaceLightDir(i.worldPos));

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate( dot(worldNormal,worldLightDir) );
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
               
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz );
                //可以直接用unity内置函数写
                //fixed3 viewDir = normallize(UnityWorldSpaceViewDir(i.worldPos));
                
                fixed3 halfDir = normalize( worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max( 0, dot(worldNormal,halfDir) ) ,_Gloss);
                
                return fixed4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}

//可以看出 Blinn-Phon 光照模型的高光反射部分看起来更大、更亮一些。
//在实际渲染中，绝大多数情况 们都会选择 Bl -Phon 光照模型。
//这两种光照模型都是经验模型也就是说不应该认为 Blinn-Phong模型是对“正确的"Phon 模型的近似。实际上，在一些情况下（详见第 18 基于物理的渲染）， Blinn-Phong 换型更符合实验结果。
