precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;


#include "/utils/structures.glsl"
vec3 calc_ray(in Camera cam,in float x,in float z);
vec2 D2Rand(in vec2 co);
float Gnoise(in vec2 p);
vec2 GnoiseD( in vec2 p );
float fbm( in vec2 x, in float H,in int numOctaves);
vec2 fbmD( in vec2 x,in float H,in int numOctaves);



void main(){
    const float PI = 3.1415926535;
    vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    float st_x = st.x;
    float st_z = st.y;
    

    Camera cam;
    cam.pos = vec3(0.0,0.0,1.5);
    cam.fov = (PI*30.0)/(2.0*180.0);
    cam.up = normalize(vec3(0.0,0.0,1.0));
    cam.lookAt = normalize(vec3(0.0,4.0,-1.3));
    vec3 ray = calc_ray(cam,st_x,st_z);

    

    const float HD_step = 0.01;
    const float MD_step = 0.1;
    const int HD_loop = 120;
    const int MD_loop = 53;

    float totlength = 0.0;
    float beflength = 0.0;
    bool ishit = false;

    const float H = 1.0;
    const int numOctaves = 8;
    const vec3 skycol = vec3(0.01,0.01,0.03);
    vec3 sky_vec = -vec3(0.0,0.0,1.0);
    sky_vec = normalize(sky_vec);

    const vec3 suncol = vec3(0.92,0.9,0.9);
    vec3 sun_vec = -vec3(1.0,1.0,1.0);
    sun_vec = normalize(sun_vec);

    vec3 rev_vec = -vec3(-1.0,-1.0,1.0);
    rev_vec = normalize(rev_vec);

    const vec3 b_albedo = vec3(0.15,0.05,0.05);
    const vec3 g_albedo = vec3(0.05,0.18,0.03);
    const float b = 0.005;

    vec3 rhead;
    float height;
    

    for (int i = 0; i < HD_loop; ++i){
        rhead = cam.pos+ray*totlength;
        height = fbm(rhead.xy,H,numOctaves);
        if (height > rhead.z){
            ishit = true;
            break;
        }else{
            beflength = totlength;
            totlength += HD_step;
        }

    }

    if (!ishit){
        for (int i = 0; i < MD_loop; ++i){
            rhead = cam.pos+ray*totlength;
            height = fbm(rhead.xy,H, numOctaves);
            if (height > rhead.z){
                ishit = true;
                break;
            }else{
                beflength = totlength;
                totlength += MD_step;
            }

        }
    }


    if (ishit){
        vec3 hitpos = cam.pos+ray*(totlength+beflength)/2.0;
        vec2 derivs = fbmD(hitpos.xy,H,numOctaves);
        vec3 norm = normalize(vec3(derivs,-1.0));
        vec3 col = vec3(0.0);

        vec3 mt_albedo = (length(derivs)>1.08) ? b_albedo: g_albedo;


        vec3 st = hitpos + norm*0.05;
        vec3 lv = -sun_vec;
        bool isshadow = false;
        for (int i = 1 ; i < 100; ++i){
            rhead = st+ float(i)*0.01*lv;
            height = fbm(rhead.xy,H,numOctaves);
            if (rhead.z < height){
                isshadow = true;
                break;
            }
        }

        vec3 sunpow = (isshadow) ? suncol : suncol*0.05;

        col += vec3(dot(sky_vec,norm)*skycol);
        col += vec3(dot(sun_vec,norm)*sunpow);
        col += vec3(dot(rev_vec,norm)*suncol*0.15);
        col = col*mt_albedo;





        float fogAmount = 1.0 - exp( -totlength*b );
        vec3  fogColor  = vec3(0.8,0.9,1.0);
        col =  mix( col, fogColor, fogAmount );

        col = pow(col,vec3(1.0/2.2));
        gl_FragColor = vec4(col,1.0);

    }else{
        vec3 col = vec3(0.3,0.5,0.7);
        float fogAmount = 1.0 - exp( -totlength*b );
        vec3  fogColor  = vec3(0.8,0.9,1.0);
        col =  mix( col, fogColor, fogAmount );
        col = pow(col,vec3(1.0/2.2));
        gl_FragColor = vec4(col,1.0);
    }
    

}

vec3 calc_ray(in Camera cam,in float x,in float z){
    vec3 side = normalize(cross(cam.lookAt,cam.up));
    return normalize(sin(cam.fov)*x*side+cos(cam.fov)*cam.lookAt+sin(cam.fov)*z*cam.up);
}

//適当
//-1〜1が帰る。
vec2 D2Rand(in vec2 co){
    float a = fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    float b = fract(sin(dot(co.xy ,vec2(31.1438,11.233))) * 134758.4123);
    return 2.0*vec2(a,b)-1.0;
}

// vec2 D2Rand( in vec2 x )  // replace this by something better
// {
//     const vec2 k = vec2( 0.3183099, 0.3678794 );
//     x = x*k + k.yx;
//     return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
// }

float Gnoise(in vec2 p){
    vec2 i = floor( p );
    vec2 f = fract( p );

    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);  
    
    vec2 ga = D2Rand( i + vec2(0.0,0.0) );
    vec2 gb = D2Rand( i + vec2(1.0,0.0) );
    vec2 gc = D2Rand( i + vec2(0.0,1.0) );
    vec2 gd = D2Rand( i + vec2(1.0,1.0) );
    
    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd);
}


vec2 GnoiseD( in vec2 p )//derivertive
{
    vec2 i = floor( p );
    vec2 f = fract( p );

    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);  
    
    vec2 ga = D2Rand( i + vec2(0.0,0.0) );
    vec2 gb = D2Rand( i + vec2(1.0,0.0) );
    vec2 gc = D2Rand( i + vec2(0.0,1.0) );
    vec2 gd = D2Rand( i + vec2(1.0,1.0) );
    
    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return vec2( ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

float fbm( in vec2 x, in float H,in int numOctaves)
{    
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    for( int i=0; i<numOctaves; i++ )
    {
        t += a*Gnoise(f*x);
        f *= 2.0;
        a *= G;
    }
    return t;

}

vec2 fbmD( in vec2 x,in float H,in int numOctaves)
{

    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    vec2 d = vec2(0.0);

    for( int i=0; i<numOctaves; i++ )
    {
        d += a*GnoiseD(f*x);
        f *= 2.0;
        a *= G;
    }
    return d;
}