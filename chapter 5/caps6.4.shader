// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/caps6.4"
{
    Properties{
        //为了得到并且控制材质的漫反射颜色，我们首先在 Shader Properties 语义块中声明了Color 类型的属性，并把它的初始值设为白色：
        _Diffuse("Diffuse",Color) = (1.0,1.0,1.0,1.0)
    }

    SubShader{
        pass{
            //然后，我们在 SubShader 语义块中定义了 Pass 语义块 这是因为顶点／片元着色器的代码需要写在 Pass 语义块，而非 SubShader 语义块中
            //ps:表面着色器在subsshader里，片元/顶点着色器在pass里
            Tags{"LightMode" = "ForwardBase"}
            //LightMode 标签是 Pass 标签中的一种，它用于定义该 Pass Unity 的光照流水线中的角色，只有定义了正确的 LightMode,我们才能得到 Unity 的内置光照变量

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Lighting.cginc"

            //为了在 Shader 中使用 Properties 语义块中声明的属性，我们需要定义一个和该属性类型相匹配的变量：
            fixed4 _Diffuse; 

            //定义了顶点着色器的输入和输出结构体（输出结构体同时也是片元着色器的输入结构体）
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //为了访问顶点的法线，需要在a2v中定义一个normal变量，并通过使用NORMAL语义来告诉Unity 模型顶点的法线信息存储到 normal 变量中。
            };
            
            struct v2f {
                float4 pos : SV_POSITION;
                fixed3 color : COLOR;
                //为了把在顶点着色器中计算得到的光照颜色传递给片元着色器 我们需要在v2f中定义color变量，且并不是必须使用COLOR，一些会使用 TEXCOORDO语义
            };

            v2f vert (a2v v ){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //由漫反射公式知需要4个元素：光源的颜色、材质的漫反射颜色Diffuse 、顶点法线normal 以及光源方向。
                //本例已知 材质漫反射颜色_Diffuse 顶点法线v.normal  还需得到 光源颜色和光源方向
                //要进行公式中顶点法线normal 以及光源方向的点积，首先要统一点积的空间位置，这里统一转化成了世界空间
                //*******上一条自己的理解：物体统一的空间里世界空间,要想点成，先要统一空间，再归一化      点成过来的计算得到的是diffuse，是颜色值，不是坐标或者点，因此可以直接进入下一轮，不需要在变换空间
                
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //通过 Unity 的内置变量UNITY LIGHTMODEL_AMBIE 得到了环境光部分。
                
                fixed3 worldNormal = normalize( mul( v.normal, (float3x3)unity_WorldToObject ) );
                //这一步是将法线转化成世界空间
                //1.normalize 归一化处理函数
                //2.mul函数 是表示矩阵M和向量V进行点乘，得到一个向量Z，这个向量Z就是对向量V进行矩阵变换后得到的值。
                //          对drictX ：mul(V,M)    对opengl ：mul(M,V)
                //3._World2Object：当前世界矩阵的逆矩阵          (float3x3)_World2Object：要截取_World20bject 的前三行前三列
                //// 函数更新   Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject
                
                fixed3 worldLight = normalize( _WorldSpaceLightPos0.xyz );
                //这一步是将光线方向转化成世界空间
                //_WorldSpaceLightPos0：得到世界坐标中光源的位置矢量或者方向向量
                //这里只是单一平行光照，所以可以这样直接得到，当光源复杂后不能这么用

                fixed3 diffuse = _LightColor0.rgb  * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));
                //unity 提供给我们一个内置变量_LightColor0 来访问该pass处理的光源颜色和强度信息
                //saturate函数：（saturate(x)的作用是如果x取值小于0，则返回值为0。如果x取值大于1，则返回值为1。若x在0到1之间，则直接返回x的值.）
                //这里saturate函数是为了防止归化后的结果为负，使它的值在0-1之间
                
                o.color = diffuse + ambient;
                //我们对环境光和漫反射光部分相加，得到最终的光照结果。
                return o;
            }

            //直接输出顶点颜色
            fixed4 frag (v2f i):SV_TARGET {
                return fixed4( i.color,1.0 );
            }            
            
            ENDCG

        }
    }

    Fallback "Diffuse"
    //Fallback在subshader后面
}


//总结：对千细分程度较高的模型，逐顶点光照已经可以得到比较好的光照效果了。
//但对某些细分程度较低的模型，逐顶点光照就会出现些视觉问题，例如我们可以在图 6.6 中看到在胶觉体的背光面与向光而交界处有一些锯齿。为了解决这些问题，我们可以使用逐像素的漫反射光照