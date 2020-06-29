float fbm( in vecN x, in float H )
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
    for( int i=0; i<numOctaves; i++ )
    {
        t += a*noise(f*x);
        //aが係数なので、微分を一緒に出したいときは微分値にもaかけて足しておけばOK
        f *= 2.0;
        //frequencyが二倍.2.01とか1.99とかにするとunnaturalなのが作れるらしい。
        a *= G;
    }
    return t;
}


//fbm微分値あちバージョン。なぜか係数をbとfで分割している(なんで？)
vec4 fbm( in vec3 x, int octaves )
{
    float f = 1.98;  // could be 2.0
    float s = 0.49;  // could be 0.5
    float a = 0.0;
    float b = 0.5;
    vec3  d = vec3(0.0);
    mat3  m = mat3(1.0,0.0,0.0,
    0.0,1.0,0.0,
    0.0,0.0,1.0);
    for( int i=0; i < octaves; i++ )
    {
        vec4 n = noised(x);
        a += b*n.x;          // accumulate values
        d += b*m*n.yzw;      // accumulate derivatives
        b *= s;
        x = f*m3*x;
        m = f*m3i*m;
    }
    return vec4( a, d );
}