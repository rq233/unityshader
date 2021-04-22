// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/caps6.5.2"
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
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                
                
                //先计算了入射光线方向关于表面法线的反射方向 reflectDir
                //由千 CG reflect 函数的入射方向要求是由光源指向交点处的，因此我们需要对 worldLightDir 取反后再传给 reflect 函数
                

                //我们通过_ WorldSpaceCameraPos 得到了世界空间中的摄像机位置，再通过和顶点相减即可得到世界空间下的视角方向。
                //此时顶点位置是模型空间的，需要变换到世界间下，和_ WorldSpaceCameraPos统一空间才有意义
                

                //pow函数 pow(x,y)  表示求x的y次方
                
                
                return o;
            }

            //负责计算漫反射和高光反射部分
            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize( _WorldSpaceLightPos0.xyz );

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate( dot(worldNormal,worldLightDir) );
                fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz );
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)) ,_Gloss);
                
                return fixed4(ambient + diffuse + specular,1.0);
            }
            ENDCG
        }
    }
    Fallback "Specular"
}
