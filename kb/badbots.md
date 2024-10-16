# List of Bad Bots
ahrefsbot
amazonbot
baiduspider
barkrowler
bingbot
bytespider
crawler4j
curl
dataforseo
dotbot
duckduckbot
exabot
facebookexternalhit
googlebot
gptbot
gptbot
linkedinbot
meta-externalagent
mj12bot
petalbot
pinterest
qwantbot
scrapy
semrush
semrushbot
seznambot
slurp
sogou
twitterbot
wget
yandexbot

# Nginx Block
```
map $http_user_agent $bad_bot {
    default 0;
    ~*facebookexternalhit 1;
    ~*meta-externalagent 1;
    ~*googlebot 1;
    ~*semrushbot 1;
    ~*bingbot 1;
    ~*mj12bot 1;
    ~*ahrefsbot 1;
    ~*barkrowler 1;
    ~*amazonbot 1;
    ~*gptbot 1;
    ~*bytespider 1;
    ~*petalbot 1;
    ~*slurp 1;
    ~*duckduckbot 1;
    ~*baiduspider 1;
    ~*yandexbot 1;
    ~*sogou 1;
    ~*exabot 1;
    ~*twitterbot 1;
    ~*linkedinbot 1;
    ~*pinterest 1;
    ~*dotbot 1;
    ~*crawler4j 1;
    ~*dataforseo 1;
    ~*scrapy 1;
    ~*wget 1;
    ~*curl 1;
}

if ($block_scraping_request) {
    return 403; # Forbidden
}