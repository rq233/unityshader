Shader "Unlit/chapter7.1.1"
{
    Properties{
        _MainTex ("Main Tex",2D) = "white"{}
        //_MainTex:纹理名字 2d：纹理属性的声明方式 “white”:内置纹理名字，这里也就是一个白色的纹理
        _Color ("Color Tint",Color) = (1,1,1,1)
        _Specular ("Specular",Color) = (1,1,1,1)
        //控制高光的反射颜色
        _Gloss ("Gloss",Range(8.0,256)) = 20
        //控制高光反射区域大小
    }

    SubShader{
        Pass{
            //先看看用啥标签
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //看是否还需要包含进 Unity 的内置文件
            #include "Lighting.cginc"

            //声明与上面属性类型相匹配的变量，以便和材质面板中的属性进行匹配
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //要为纹理类型的属性声明一个 float4 类型的变量MainTex_ST ，我们需要使用纹理名_ST的方式来声明某个纹理的属性。
            //ST 是缩放 (sca le 和平移 (translation 的缩写。 MainTex_ST可以让我们得到该纹理的缩放和平移 （偏移）值 
            //_MainTex_ST.xy 存储的是缩放值，而MainTex_ST.zw 存储的是偏移值
            
            fixed4 _Color;
            fixed4 _Specular;
            float _Gloss;

            //顶点着色器的输入
            //position normal texcoord这些都是语义，存放着相关信息，是由mesh render提供的
            struct a2v {
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                float4 texcoord :TEXCOORD0;
            };

            //顶点着色器的输出
            struct v2f {
                float4 Pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                float2 uv :TEXCOORD2;
            };

            //构建顶点着色器
            v2f vert (a2v v){
                //定义一个输出声明，不然不能将东西输出渲染屏幕
                //顶点着色器需要输出啥就要写些啥
                v2f o;
                o.Pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //使用纹理的属性值_MainTex_ST 来对顶点纹理坐标进行变换，得到最终的纹理坐标
                //首先使用缩放属性_MainTex_ST.xy 对顶点纹理坐标进行缩放   然后再使用偏移属性 MainTex ST.zw 对结果进行偏移。
                //还有一种写法   ：o.uv = TRANSFROM_TEX(v.texcoord,_MainTex);
                // TRANSFROM_TEX 是unity的内置宏  他在unityCG.cginc里面 定义:#define TRANSFROM_TEX (tex,name)= tex.xy * name_ST.xy + name_ST.zw
                // tex.xy:纹理坐标  name_ST:纹理名字
                return o;
            }

            //构建片元着色器
            //思考片元着色器里面要干什么？-计算物体纹理包含的要素
            //纹理要素里面有些什么：漫反射：diffuse 高光：specular  环境光：ambient   按道理还有ao和法线贴图 这里没计算
            fixed4 frag (v2f i):SV_TARGET{
                //根据计算公式，先写出需要的要素

                //计算漫反射
                //漫反射公式  diffuse = 光源颜色强度 * 自己的材质纹理albedo * max(0,法线和光照方向的点积)
                //需要处理的：albedo 法线 光照方向
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(worldNormal,worldLightDir));

                //计算高光反射
                //高光反射公式  这里用的是B-F模型 specular = 光源颜色强度 * 自己的高光颜色specular * pow(max(0,法线和光照方向的点积)的_gloss次方)
                //BF模型的光照方向需要求  这里的光照方向是halfDir  halfDir公式：光照方向+视角方向
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfDir = normalize(worldLightDir+viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular * pow(max( 0 , dot(worldNormal,halfDir) ),_Gloss);

                //计算环境光
                //环境光可以通过 Unity 的内置变量UNITY LIGHTMODEL_AMBIE 得到，但这里还有物体本身材质会影响到他，所以还需要乘albedo
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //计算总纹理
                return fixed4( diffuse + specular + ambient,1.0); 
            }

            ENDCG


        }
    }
    Fallback "Specular"
}