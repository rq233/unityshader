Shader "Unlit/7.4.1"
{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex("Main Tex",2D) = "white"{}

        _BumpMap("Bump Map",2D) = "white"{}
        _BumpScale("Bump Scale" ,float) = 1.0

        _Specular("Specular",Color) = (1,1,1,1)
        _SpecularScale("Specular Scale" ,float) = 1.0
        _SpecularMask("Specular Mask",2D) = "white"{}
        _Gloss("Gloss",Range(2,255)) = 20
    }

    SubShader{
        pass{
            Tags{"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            
            float _BumpScale;
            fixed4 _Specular;
            float _SpecularScale;
            sampler2D _SpecularMask;
            float _Gloss;

            //定义顶点着色器的输入结构
            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                float4 tangent :TANGENT;
                float4 texcoord :TEXCOORD0;
            };

            //定义顶点着色器的输出结构
            struct v2f{
                float4 pos :POSITION;
                float2 uv :TEXCOORD0;
                float3 lightDir :TEXCOORD1;
                float3 viewDir :TEXCOORD2;
            };

            //构建顶点着色器
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //这里将光线方向和视角方向到切线空间，目的是为了和法线进行计算
                //这里的法线储存在凹凸贴图bump里，是位于切线空间里，因为切线空间处理的法线更好用
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
                return o;
            }

            //片元着色器计算 diffuse specular  ambient
            float4 frag (v2f i) :SV_TARGET{
                //先将需要计算的单一要素归一化
                fixed3 tangentLightDir = normalize(i.lightDir);
                fixed3 tangentViewDir = normalize(i.viewDir);

                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z =  sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                //开始计算
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));
                //BF光照模式使用halfDir光照方向来计算
                fixed3 halfDir = normalize( tangentLightDir + tangentViewDir);
                //遮罩处理
                fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;

                fixed3 specular = _LightColor0.rgb * albedo * pow( max(0,dot(tangentNormal,halfDir)),_Gloss) * specularMask;
                return fixed4( diffuse + ambient + specular, 1.0); 

            }
            ENDCG

        }
    }Fallback "Specular"
}