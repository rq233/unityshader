Shader "Unlit/7.2.1"
{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _MainTex("MainTex",2D)="White"{}
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8,256))=30

        _BumpMap("Normal Map",2D)="bump"{}
        //对于法线纹理_BumpMap, 我们使用 "bump"作为它的默认值."bump" Unity内置的法线纹理，当没有提供任何法线纹理时 "bump"就对应了模型自带法线信息。 
        _BumpScale("Bump Scale",float)=20.0
        //BumpScale 则是用于控制凹凸程度的，当它为0时，意味着该法线纹理不会对光照产生任何影响。
    }

    SubShader{
        pass{
            Tags{"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Specular;
            float _Gloss;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;

            //第一种选择是在切线空间下进行光照计算，此时我们需要把光照方向、视角方向变换到切线空间下；
            //从效率上来说，第一种方法往往要优于第二种方法，因为我们可以在顶点着色器中就完成对光照方向和视角方向的变换
            //而第二种方法由千要先对法线纹理进行采样，所以变换过程必须在片元着色器中实现，这意味若我们需要在片元着色器中进行一次矩阵操作。
            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                fixed4 texcoord :TEXCOORD0;
                float4 tangent :TANGENT;
            };
            struct v2f{
                float4 pos :SV_POSITION;
                float4 uv :TEXCOORD0;
                float3 lightDir :TEXCOORD1;
                float3 viewDir :TEXCOORD2;
            };

            //顶点着色器需做的事：1.将两个纹理储存进一组坐标中  2.将光照方向和观察方向转化到切线空间。 为法线的计算做好准备
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //因为有两张贴图，所以我们用两个函数来储存纹理
                //MainTex BumpMap 常会使用同一组纹理坐标，出于减少插值寄存器的使用数目的目的， 我们往往只计算和存储一组纹理坐标即可
                //这一组纹理中，xy 分扯存储了_MainTex 的纹理坐标，zw 分量存_BumpMap纹理坐标
                //xyz表示切线方向，而第四个分量w表示副切线的方向。如果副切线方向不对,最终法线会反向
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                
                //我们把模型空间切线方向、副切线方向和法线方向按行排列来得到从模型空间到切线空间的变换矩阵 rotation 。
                //计算副切线时我们使用 .tangent.w 和叉积结果进行相乘 这是因为和切线与法线方向都垂直的方向有两个 w决定了我们选择其中哪个方向。
                TANGENT_SPACE_ROTATION;
                o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
                o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;
                //将观察方向和光照方向从模型空间转化到切线空间
                //ObjSpaceLightDir:得到模型空间光照方向    ObjSpaceViewDir：得到模型空间观察方向
                //rotation起变换矩阵的作用
                return o;
            }

            //片元着色器应该做的事情：1.得到切线空间的法线方向 2.在切线空间下进行光照计算
            fixed4 frag(v2f i):SV_TARGET{
                //统一转换切线空间，顶点着色器中已将其转化，直接归一化就行
                fixed3 tangentLightDir =normalize(i.lightDir);
                fixed3 tangentViewDir =normalize(i.viewDir);
                
                //得到切线空间法线并进行映射
                //tex2D 对法线纹理 BumpMap 进行采样,注意这个采样值暂时还不能用，需要映射
                fixed4 packedNormal =tex2D(_BumpMap,i.uv.zw);
                //使用法线纹理中的法线值来代替模型原来的法线参与光照计算
                fixed3 tangentNormal;
                tangentNormal = UnpackNormal(packedNormal);
                //作法线映射
                tangentNormal.xy *= _BumpScale;
                //计算法线的z分量,保证z方向的为正
                tangentNormal.z = sqrt(1.0 - saturate( dot(tangentNormal.xy,tangentNormal.xy)));
                
                //光照模型计算照旧
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(tangentNormal,tangentLightDir));
                fixed3 halfDir = normalize( tangentLightDir + tangentViewDir );
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( max(0,dot(tangentNormal,halfDir)),_Gloss);
                
                return fixed4(diffuse + specular + ambient,1.0);
            }
            ENDCG

        }
    }
    Fallback "Specular"
}