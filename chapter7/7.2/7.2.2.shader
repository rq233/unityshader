// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/7.2.2"
{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _MainTex("MainTex",2D)="White"{}
        _Specular("Specular",Color)=(1,1,1,1)
        _Gloss("Gloss",Range(8,256))=30

        _BumpMap("Normal Map",2D)="bump"{}
        //对于法线纹理_BumpMap, 我们使用 "bump"作为它的默认值."bump" Unity内置的法线纹理，当没有提供任何法线纹理时 "bump"就对应了模型自带法线信息。 
        _BumpScale("Bump Scale",float)=20.0
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

            //第二种选择是在世界空间下进行光照计算，此时我们需要把采样得到的法线方向变换到世界空间下
            //从通用性角度来说，第二种方法要优于第一种方法，因为有时我们需要在世界空间下进行一些计算，
            //例如在使用Cubemap 进行环境映射时，我们需要使用世界空间下的反射方向对 Cubemap 进行采样
            struct a2v {
                float4 vertex :POSITION;
                float3 normal :NORMAL;
                fixed4 texcoord :TEXCOORD0;
                float4 tangent :TANGENT;
                //它是float4类型，需要用tangent.w 分量来决定切线空间中的第三个坐标轴一副切线的方向性。
            };

            struct v2f {
                float4 pos :SV_POSITION;
                float4 uv :TEXCOORD0;
                //每个插值寄存器最多只能存储 float4 大小的变批，对于矩阵这样的变换，我们可以把它们按行拆成多个变扯再进行存储。
                //上面代码中的 TtoWO TtoWl TtoW2 就依次存储了从切线空间到世界空间的变换矩阵的每一行
                //为了充分利用插值寄存器的存储空间，我们把世界空间下的顶点位置存储在这些变堆的分址中。
                float4 T2W0 :TEXCOORD1;
                float4 T2W1 :TEXCOORD2;
                float4 T2W2 :TEXCOORD3;
            };

            //在顶点着色器中计算从切线空间到世界空间的变换矩阵，把它传递给片元着色器
            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //MainTex BumpMap 常会使用同一组纹理坐标，出 减少插值寄存器的使用数目的目的， 我们往往只计算和存储一组纹理坐标即可）
                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

                float3 worldPos = mul( unity_ObjectToWorld , v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;

                
                //如果一个变换中仅存在平移和旋转变换，那么这个变换的逆矩阵就等于它的转隍矩阵，
                //切线空间到模型空间的变换正是符合这样要求，从模型空间到切线空间的变换矩阵就是从切线空间到模型空间的变换矩阵的转置矩阵
                //从切线空间到模型空间的变换矩阵：在顶点看色器中按切线 (x 轴）、副切线（y 轴）、法线(z 轴）的顺序按列排列即可得到
                o.T2W0 = float4(worldTangent.x , worldBinormal.x , worldNormal.x , worldPos.x);
                o.T2W1 = float4(worldTangent.y , worldBinormal.y , worldNormal.y , worldPos.y);
                o.T2W2 = float4(worldTangent.z , worldBinormal.z , worldNormal.z , worldPos.z);

                return o;
            }

            //只需要在片元着色器中把法线纹理中的法线方向从切线空间变换到世界空间下
            fixed4 frag ( v2f i ) :SV_TARGET{
                float3 worldPos = float3( i.T2W0.w , i.T2W1.w , i.T2W2.w );
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 bump = UnpackNormal( tex2D(_BumpMap , i.uv.zw) );
                bump.xy *= _BumpScale;
                bump.z = sqrt(1.0-saturate(dot(bump.xy,bump.xy)));
                bump = normalize(half3( dot(i.T2W0.xyz ,bump), dot(i.T2W1.xyz,bump), dot(i.T2W2.xyz,bump) ));

                //unpacknormal 在unity.cg中的实现
                //，在某些平台上由于使用了 DXT5nm 的压缩格式，因此需要针对这种格式对法线进行解码
                //用这种压缩方法就可以减少法线纹理占用的内存空间。
                // DXT5nm 格式的法线纹理中，纹素的a通道（即w分量）对应了法线的分扯， g通道对应了法线y的分量，而纹理的 r.b 通道则会被舍弃，法线的 分批可以由 xy批推导而得。
                /* inline fixed3 UnpackNormalDXT5nm (fixed4 packednormal){
                    fixed3 normal;
                    normal.xy = UnpackNormal.wy*2-1;
                    normal.z = sqrt(1- saturate(dot(normal.xy,normal.xy)));
                    return normal; 
                }
                inline fixed3 Unpackednormal (fixed4 packednormal){
                    #if defined(UNITY_NO_DXT5nm)
                    return packednormal,xyz*2-1;
                    #else 
                    return UnpackNormalDXT5nm(packednormal);
                    endif
                } */

                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0,dot(bump,lightDir));
                fixed3 halfDir = normalize( lightDir + viewDir );
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow( max(0,dot(bump,halfDir)),_Gloss);
                
                return fixed4(diffuse + specular + ambient,1.0);
            }

            ENDCG
        }
    }
    Fallback "Specular"
}