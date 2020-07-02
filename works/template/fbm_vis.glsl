precision mediump float;
uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

float Basicrand(in vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

//適当
//-1〜1が帰る。
vec2 D2Rand(in vec2 co){
    // float a = Basicrand(co);
    // float b = Basicrand(co*a);
    // float c = Basicrand(co*a*b);
    float a = fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    float b = fract(sin(dot(co.xy ,vec2(31.1438,11.233))) * 134758.4123);
    return 2.0*vec2(a,b)-1.0;
}

float vNoise2D(in vec2 x){
    vec2 p = floor(x);
    vec2 w = fract(x);

    vec2 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    float a = Basicrand(p+vec2(0.0,0.0));
    float b = Basicrand(p+vec2(1.0,0.0));
    float c = Basicrand(p+vec2(1.0,1.0));
    float d = Basicrand(p+vec2(0.0,1.0));

    float k1 = b-a;
    float k2 = d-a;
    float k3 = a-b+c-d;

    return a+k1*u.x+k2*u.y+k3*u.x*u.y;

}

vec3 Gnoise( in vec2 p )
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

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
    //gradient noiseはほっとくと暗くなる(負の値を取りうる)ので*0,5して+0.5とかで適当に補ってあげたほうが良い。
}

float fbm( in vec2 x, in float H )
{    
    //Hは直前の値をどのくらい覚えているか。fractral brown motionのfractal部分を担う部分。
    //H=1/2が通常の無相関ブラウン運動。
    //相関係数を頑張って計算するとH=1/2で無相関、H>1/2で正相関、H<1/2で負の相関になる。
    //つまりHが小さいほどランダム味が強く、Hが大きいほどランダム味が小さくなめらかになる。
    //Hは自己相似性を保つscalefactorにも関係する。
    //xをU倍した時、YをU^(-H)倍するとスケールが合う。この関係でH=1が最も自然に見える(スケール倍率が等縮尺)
    float G = exp2(-H);
    float f = 1.0;
    float a = 1.0;
    float t = 0.0;
    const int numOctaves = 8;
    for( int i=0; i<numOctaves; i++ )
    {
        //t += a*Gnoise(f*x).x;
        t += a*vNoise2D(f*x);
        //aが係数なので、微分を一緒に出したいときは微分値にもaかけて足しておけばOK
        f *= 2.0;
        //frequencyが二倍.2.01とか1.99とかにするとunnaturalなのが作れるらしい。
        a *= G;
    }
    return t;
}


void main(){
    //2d grad noise show
    // vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    // vec2 expanded = st*vec2(8.0);
    // vec3 k = Gnoise(expanded);
    // gl_FragColor = vec4(0.5+0.5*vec3(k.x),1.0);

    //grad noise wave silhouette
    // vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    // vec2 expanded = vec2(st.x*10.0,100.0);
    // vec3 k = Gnoise(expanded);
    // gl_FragColor = vec4(vec3(step(1.0*k.x,st.y)),1.0);

    //fbm with grad noise show
    // vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    // vec2 expanded = st*8.0;
    // float k = fbm(expanded,1.0);
    // gl_FragColor = vec4(vec3(k)*0.5+0.2,1.0);

    //fbm with grad noise silhouette
    vec2 st = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    vec2 expanded = vec2(st.x*0.5+1.0,1.0);
    float k = fbm(expanded,1.0);
    gl_FragColor = vec4(vec3(step(1.5*k-2.0,st.y)),1.0);

}