// struct Camera{
//     vec3 pos;
//     float fov;
//     vec3 lookAt;
//     vec3 up;
// };

// struct_cameraだといちいち定義するのがだるいので、mat4に押し込んで見ようかと思う。
//posx,lookatx,upx,fov
//posy,lookaty,upy, 0
//posz,lookatz,upz, 0
//0,     0,     0 , 0

//これもうObjectもmat4とかでよくね？パラメータ8つあったら定まるのでは？
//定まりそう。Objectもmat4で定義します。
//posx,rotx,type,  param4
//posy,roty,param1,param5
//posz,rotz,param2,param6
//0,     0, param3,param7
//typeはfloatになるので、ifで書いてもいいんだけど、せっかくGPUなので
//たとえばまぁとりあえずせいぜい4個しかオブジェクトの種類がないとすれば、
//vec4 = {0.0,1.0,2.0,3.0}
//として、typeを1.001みたいなちょっとだけ大きい値にしておくと、type-mをして、1.0-step(0.1,type-m)で
//該当の番号のところだけが1になるvec4になる
//vec4(0.0,1.0,0.0,1.0)みたいな
//そしたら後は全部にdistancefunc計算して内積取ればOK
//微分も同じはず。

//colorは一回しか計算しないし、すなおにd<epsならリターンを繰り返せばいい気はする。


//glslのmatはmat[0]みたいな感じにすると列が返ってくる(要は縦ベクトルやな)
//返ってきたvec4はxyzwでアクセス可能。

//3Dvaluenoiseでdisplaceするみたいなときは表面の法線は数値微分の方が簡単っぽいね。
precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;


const int obj_num = 2;

vec3 calc_ray(inout mat4 cam,in float x,in float z);
float distance_func(in mat4 obj,in vec3 pos);
vec3 calc_norm(in mat4 objs[obj_num],in vec3 hitpos);
float Basicrand(in vec2 co);
float fbm( in vec3 x);
float box_df(in vec3 p,in vec3 size);
float round_box(in vec3 p,in vec3 size,float r);
float noised( in vec3 x );
float map(in mat4[obj_num] objs,in vec3 pos);
int whichhit(in mat4[obj_num] objs,in vec3 hitpos);

// float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
// {
//     float res = 1.0;
//     for( float t=mint; t<maxt; )
//     {
//         float h = map(ro + rd*t);
//         if( h<0.001 )
//             return 0.0;
//         res = min( res, k*h/t );
//         t += h;
//     }
//     return res;
// }


void main(){
    const float PI = 3.1415926535;
    vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);

    mat4 cam;
    cam[0].xyz = vec3(0.0,0.0,3.0);//pos
    cam[1].xyz = normalize(vec3(0.0,8.0,-4.0));//lookat vec
    cam[2].xyz = normalize(vec3(0.0,0.0,1.0));//up
    cam[3].x = (PI*30.0)/(2.0*180.0);//fov

    vec3 ray = calc_ray(cam,st.x,st.y);

    mat4 objs[obj_num];

    objs[0][0].xyz = vec3(0.0,5.0,0.0);
    objs[0][2] = vec4(0.0,vec3(1.0,0.5,0.2));//size
    objs[0][3].x=0.04;//round

    objs[1][0].xyz = vec3(0.0,5.0,-0.4);
    objs[1][2] = vec4(1.0,vec3(2.0,3.0,0.2));//size


    float max_dis = 100.0;
    float min_dis = 0.001;
    float totdis = 0.0;
    const int max_loop = 100;
    vec3 rayhead;
    float dist;
    bool ishit = false;
    for (int i = 0; i < max_loop; ++i){
        rayhead = cam[0].xyz+ray*totdis;
        dist = map(objs,rayhead);

        ishit = dist<min_dis && totdis <= max_dis;

        if (ishit) break;
        if (totdis>max_dis) break;

        totdis += dist;

    }

    if (ishit){
        vec3 hitpos = cam[0].xyz+totdis*ray;
        vec3 norm = calc_norm(objs,hitpos);
        vec3 lvec = -normalize(vec3(0.5,0.5,-1.0));
        float lpow = clamp(dot(lvec,norm),0.0,1.0);

        int which = whichhit(objs,hitpos);
        vec3 albedo = (which==0)?vec3(0.2,0.1,0.1):vec3(0.3,0.3,0.3);

        // //どれにヒットしたかの計算はどうしようね。
        //境界付近の扱いだけが困る。
        gl_FragColor = vec4(vec3(lpow)*albedo,1.0);
        // gl_FragColor = vec4(vec3(1.0),1.0);

    }else{
        gl_FragColor = vec4(vec3(0.1),1.0);
    }

    
}

vec3 calc_ray(inout mat4 cam,in float x,in float z){
    vec3 lookAt = cam[1].xyz;
    vec3 up = cam[2].xyz;
    vec3 side = normalize(cross(lookAt,up));
    float fov = cam[3].x;
    vec3 trueup = normalize(cross(side,lookAt));
    cam[2].xyz=trueup;
    return normalize(sin(fov)*x*side+cos(fov)*lookAt+sin(fov)*z*up);
}

float map(in mat4[obj_num] objs,in vec3 pos){
    //複数のオブジェクトに関して距離関数を求めてUnionなり何なりを取るさらなるラッパー
    //言うなればこれが真の距離関数。
    float ret = 1e9;
    for (int i = 0; i < obj_num; ++i){
        float d = distance_func(objs[i],pos);
        ret = min(ret,d);
    }
    return ret;
}

int whichhit(in mat4[obj_num] objs,in vec3 hitpos){
    int ret = -1;
    for (int i = 0; i < obj_num; ++i){
        float d = distance_func(objs[i],hitpos);
        if (d<0.001) {ret = i; break;}
    }
    return ret;
}

float distance_func(in mat4 obj,in vec3 pos){
    //objectとposから距離を求める距離関数のラッパー
    vec3 p = pos-obj[0].xyz;
    vec4 mask = vec4(0.0,1.0,2.0,3.0);
    mask = 1.0-step(0.3,abs(vec4(obj[2].x)-mask));
    // float d1 = box_df(p,obj[2].yzw)+fbm(p*2.0)*0.02;
    float d1 = round_box(p,obj[2].yzw,obj[3].x)+fbm(p*2.3)*0.06;
    float d2 = box_df(p,obj[2].yzw);
    float d3 = 0.0;
    float d4 = 0.0;
    return dot(mask,vec4(d1,d2,d3,d4));
}

vec3 calc_norm(in mat4 objs[obj_num],in vec3 hitpos){
    float eps = 0.0001;
    return normalize(
        vec3(
            map(objs,hitpos+vec3(eps,0.0,0.0))-map(objs,hitpos+vec3(-eps,0.0,0.0)),
            map(objs,hitpos+vec3(0.0,eps,0.0))-map(objs,hitpos+vec3(0.0,-eps,0.0)),
            map(objs,hitpos+vec3(0.0,0.0,eps))-map(objs,hitpos+vec3(0.0,0.0,-eps))
        )
    );
}

float Basicrand(in vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,23.615))) * 43758.5453);
}


float fbm( in vec3 x)
{   
    const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );

    float Gain = exp2(-1.0);//exp(-H)
    float freq = 1.0;
    float amp = 1.0;
    float ret = 0.0;
    const int numOctaves = 4;
    for( int i=0; i<numOctaves; i++ )
    {
        float n = noised(x);
        ret += amp*n;
        amp *= Gain;
        x = freq*m3*x;
    }
    return ret;
}

float box_df(in vec3 p,in vec3 size){
    vec3 q = abs(p)-size;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float round_box(in vec3 p,in vec3 size,float r){
      vec3 q = abs(p)-size;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0)-r;
}

 float noised( in vec3 x )
 {
    vec3 p = floor(x);
    vec3 w = fract(x);

    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    float a = Basicrand( p+vec3(0,0,0) );
    float b = Basicrand( p+vec3(1,0,0) );
    float c = Basicrand( p+vec3(0,1,0) );
    float d = Basicrand( p+vec3(1,1,0) );
    float e = Basicrand( p+vec3(0,0,1) );
    float f = Basicrand( p+vec3(1,0,1) );
    float g = Basicrand( p+vec3(0,1,1) );
    float h = Basicrand( p+vec3(1,1,1) );

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;


    return -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z);
 }