// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Sim5.1" { 

    //代码中没用properties语义块，它并不是必要的

    SubShader {
       Pass { 
           CGPROGRAM
           #pragma vertex vert 
           //告诉了哪个函数包含了顶点着色器代码  常见格式  #pragma vertex name
           #pragma fragment frag
           //告诉了哪个函数包含了片元着色器代码  常见格式  #pragma fragment name

           
           //***************本例使用的顶点着色器定义*********************，ps它是逐点输入的
           
           /* float4 vert(float4 v: POSITION) : SV_POSITION { 
               return UnityObjectToClipPos(v);
           } */
           
           //本函数的输入：(float4 v: POSITION)   POSITION：把模型的顶点坐标传入参数v中，v就包含了顶点的位置
           //本函数的输出：SV_POSITION    就是告诉本函数的输出是裁剪空间的顶点坐标
           //unity8.3版本更新了函数  Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
           //这里的UnityObjectToClipPos(*) 就是把顶点坐标从模型空间转化为裁剪空间  是内置的模型-观察-投影矩阵
           
           
           //***************本例使用的片元着色器定义*********************
          
           /* fixed4 frag() : SV_Target {
               return fixed4(1.0, 1.0, 1.0, 1.0);
           } */
          
           //函数的输入:没有
           //函数的输出：输入到目标储存器的颜色，是一个fixed变量    SV_Target相当于告诉渲染器把用户的输出颜色存入到目标存储器中
           
           
           //*********************定义一个结构体*********************
           //用一个结构体来定义着色器的输入
           struct a2v{
               float4 vertex : POSITION;
               // POSITION语义告诉unity, 用模型空间的顶点坐标填充vertex变量
               float3 normal : NORMAL;
               // NORMAL语义告诉Unity, 用模型空间的法线方向填充normal变量
               float4 texcoord : TEXCOORD0;
               // TEXCOORDO语义告诉Unity, 用模型的第一套纹理坐标填充texcoord变量
           };
           //----在 a2v 的定义中， 我们用到了更多 Unity 支持的语义， 如 NORMAL 和 TEXCOORDO, 当它们作为顶点着色器的输入时都是有特定含义的
           //----Unity 支持的语义有： POSITION, TANGENT, NORMAL, TEXCOORDO,TEXCOORDJ, TEXCOORD2, TEXCOORD3, COLOR 等
           //----语义中的数据来源：它们是由使用该材质的 Mesh Render 组件提供的。 在每帧调用Draw Call 的时候 Mesh Render 组件会把它负责渲染的模型数据发送给 Uruty Shader
           //自定义结构体格式:
           /* struct StructName (
               Type Name : Semantic;
               Type Name : Semantic;     semantic:语义
           ); */

           //解释 a2v:  a 表示应用 (application), v 表示顶点着色器 (vertex shader), a2v 的意思就是把数据从应用阶段传递到顶点着色器中。
           /* float4 vert(a2v v) : SV_POSITION { 
               return UnityObjectToClipPos(v.vertex);
           }
           fixed4 frag() : SV_Target {
               return fixed4(1.0, 1.0, 1.0, 1.0);
           } */
           
           //*********************顶点着色器和片元着色器之间的通信*********************
           //实践中， 我们往往希望从顶点着色器输出一些数据， 例如把模型的法线、纹理坐标等传递给片元着色器。 这就涉及顶点着色器和片元着色器之间的通信。
           //使用一个结构体来定义顶点着色器的输出
           struct v2f{
               float4 pos :SV_POSITION;
               // SV_POSITION语义告诉Unity, pos里包含了顶点在裁剪空间中的位置信息
               fixed3 color : COLOR0;
               // COLORO语义可以用于存储颜色信息
           };

           //v2f用于在顶点着色器和片元着色器之间传递信息,v2f中也需要指定每个变量的语义 
           v2f vert (a2v v) {
               //声明输出结构
               v2f o;
               //顶点着色器的输出结构中， 必须包含一个变量，它的语义是 SV_POSITION。否则无法得到裁剪空间中的顶点坐标， 也就无法把顶点渲染到屏幕上。
               o.pos = UnityObjectToClipPos(v.vertex);
               // v.normal包含了顶点的法线方向 ， 其分量范围在(-1.0, 1.0]
               //下面的代码把分量范围映射到了(0.0, 1.0]
               //存储到a.color中传递给片元着色器
               o.color = v.normal*0.5 + fixed3(0.5, 0.5, 0.5);
               return o;
           };
            
          
           //片元着色器中的输入实际上是把顶点着色器的输出进行插值后得到的结果。
           fixed4 frag (v2f i):SV_Target{
               //将插值后的i.color显示到屏幕上
               return fixed4(i.color, 1.0);
           };

           

           
           ENDCG
        }
    }
}