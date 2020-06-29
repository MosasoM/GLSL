#iChannel0 "file://textures/plywood_small.jpg"
#include "/utils/structures.glsl"
#include "/utils/pbr.glsl"
#include "/utils/dist_func.glsl"
// include pathをミスると真っ暗になるので注意。

precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

#define SIZE_OF_OBJS_ARRAY 10
//このSIZEがでかすぎると貧弱GPUだとメモリクラッシュしてエラーもなく真っ黒になるので注意。気づきにくいのでかなりしんどい。


vec3 calc_ray(in Camera cam,in float x,in float z);
float distance_func(in Object obj,in vec3 rayhead);
vec3 calc_norm(in Object obj,in vec3 hitpos);
vec3 material_color(in Material mat,in vec3 n,in vec3 v,in vec3 l);
void calc_light(in Light light,in vec3 hitpos,inout vec3 light_vec);


void raymarching(in vec3 origin,in vec3 ray,in Object[SIZE_OF_OBJS_ARRAY] objs,out int hitnum,out bool ishit,out vec3 hitpos);
//inonutで渡さないと参照代入したいやつに関数内で代入が行われないと、mainで代入した値じゃなく各型ごとの初期値が勝手に代入されてバグる。
//配列を引数渡しするときは固定長じゃないと行けないので、#defineで大きめにとって渡す(constで行けるかは知らん)

//Struct hoge[num]と宣言してからhoge[0] = fuga(struct)とすることができない(なんで？)




const int obj_num = 2;
const int reflection_num = 3;


void main(){
    const float PI = 3.1415926535;
    vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    float st_x = st.x;
    float st_z = st.y;

    Light dlight;
    dlight.power = vec3(3.0);
    dlight.kind = 1;

    Material mate1;
    Material mate2;

    mate1.albedo = vec3(0.1,0.5,0.1);
    mate2.albedo = vec3(0.9,0.9,0.9);
    mate1.f0 = vec3(0.1,0.1,0.1);
    mate2.f0 = vec3(0.6,0.6,0.6);
    mate1.roughness = 0.6;
    mate2.roughness = 0.1;
    mate1.kind = 2;
    mate2.kind = 2;

    Camera cam;
    cam.pos = vec3(0.0,0.0,5.0);
    cam.fov = (PI*30.0)/(2.0*180.0);
    cam.lookAt = normalize(vec3(0.0,1.0,0.0));
    cam.up = normalize(vec3(0.0,0.0,1.0));
    cam.lookAt = normalize(vec3(0.0,15.0,0.0)-cam.pos);

    Object objs[SIZE_OF_OBJS_ARRAY];

    objs[0].pos = vec3(0.0,15.0,0.0);
    objs[0].rot = vec3(0.0,0.0,0.0);
    objs[0].kind = 1;
    objs[0].params[0] = 1.5;
    objs[0].material = mate1;
    objs[1].pos = vec3(0.0,15.0,-2.5);
    objs[1].rot = vec3(0.0,0.0,0.0);
    objs[1].kind = 2;
    objs[1].params[0] = 5.0;
    objs[1].params[1] = 10.0;
    objs[1].params[2] = 1.0;
    objs[1].material = mate2;



    vec3 origin = cam.pos;
    vec3 ray;
    ray = calc_ray(cam,st_x,st_z);
    int hitnum;
    vec3 hitpos;
    bool ishit;
    vec3 norm;
    vec3 light_vec;
    vec3 brdf = vec3(0.0);
    vec3 light_col;
    raymarching(origin,ray,objs,hitnum,ishit,hitpos);

    if (hitnum == 0){
        vec2 hp = vec2(mod(hitpos.x,1.0),mod(hitpos.y,1.0));
        vec4 tex = texture2D(iChannel0,hp);
        objs[0].material.albedo = vec3(tex.x,tex.y,tex.z);
    }
    if (ishit){
        for (int j = 0; j < obj_num; ++j){
            if (j == hitnum){
                vec3 view = normalize(origin-hitpos);
                calc_light(dlight,hitpos,light_vec);
                norm = calc_norm(objs[j],hitpos);
                brdf = material_color(objs[j].material,norm,view,light_vec);
                light_col = dlight.power*clamp(dot(norm,light_vec),0.0,0.95);
                light_col = light_col+vec3(0.5);
                gl_FragColor = vec4(light_col*brdf,1.0);
            break;
            }
        }

    }else{
        gl_FragColor = vec4(vec3(0.0),1.0);
    }


}

void raymarching(in vec3 origin,in vec3 ray,in Object[SIZE_OF_OBJS_ARRAY] objs,out int hitnum,out bool ishit,out vec3 hitpos){
    float max_dis = 100.0;
    float min_dis = 0.01;
    float rlen = 0.0;
    const int max_loop = 100;
    hitnum = -1;
    hitpos = vec3(0.0);
    ishit = false;
    for (int i = 0; i < max_loop; ++i){
        float shortest = 1e9;    
        for (int j = 0; j < obj_num; ++ j){
            float d = distance_func(objs[j],origin+ray*rlen);
            if (d < shortest){
                shortest = d;
                hitnum = j;
            }
        }
        if (rlen > max_dis){
            break;
        }
        if (abs(shortest) < min_dis){
            ishit = true;
            hitpos = origin + ray*rlen;
            break;
        }else{
            rlen += shortest;
        }
    }
}

vec3 calc_ray(in Camera cam,in float x,in float z){
    vec3 side = normalize(cross(cam.lookAt,cam.up));
    return normalize(sin(cam.fov)*x*side+cos(cam.fov)*cam.lookAt+sin(cam.fov)*z*cam.up);
}

float distance_func(in Object obj,in vec3 rayhead){
    vec3 p = rayhead-obj.pos;
    if (obj.kind == 1){
        //sphere
        return sphere_df(p,obj.params[0]);
    }else if (obj.kind==2){
        // box
        return box_df(p,vec3(obj.params[0],obj.params[1],obj.params[2]));
    }
}

vec3 calc_norm(in Object obj,in vec3 hitpos){
    float eps = 0.001;
    return normalize(
        vec3(
            distance_func(obj,hitpos+vec3(eps,0.0,0.0))-distance_func(obj,hitpos+vec3(-eps,0.0,0.0)),
            distance_func(obj,hitpos+vec3(0.0,eps,0.0))-distance_func(obj,hitpos+vec3(0.0,-eps,0.0)),
            distance_func(obj,hitpos+vec3(0.0,0.0,eps))-distance_func(obj,hitpos+vec3(0.0,0.0,-eps))
        )
    );
}

vec3 material_color(in Material mat,in vec3 n,in vec3 v,in vec3 l){
    const float PI = 3.1415926535;
    if(mat.kind==1){
        return mat.albedo/PI;
    }else if(mat.kind == 2){
        vec3 h = normalize(l+v);
        float pbr_d = pbr_D(mat.roughness,n,h);
        float pbr_v = pbr_V(mat.roughness,n,v,l);
        vec3 pbr_f = pbr_F(mat.f0,l,h);
        vec3 diff = mat.albedo/PI;
        return (vec3(1.0)-pbr_f)*diff+pbr_d*pbr_f*pbr_v;
    }
}
void calc_light(in Light light,in vec3 hitpos,inout vec3 light_vec){
    if(light.kind==1){
        light_vec = -vec3(1.0,1.0,-1.0);
        light_vec = normalize(light_vec);
    }
}





//     mat3 m = mat3(
//         a.x * a.x * r + c,        a.y * a.x * r + a.z * s,  a.z * a.x * r - a.y * s,
//         a.x * a.y * r - a.z * s,  a.y * a.y * r + c,        a.z * a.y * r + a.x * s,
//         a.x * a.z * r + a.y * s,  a.y * a.z * r - a.x * s,  a.z * a.z * r + c
//     );
//     return m*p;
// }

