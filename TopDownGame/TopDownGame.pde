// --- 유한 상태 기계 (FSM) 열거형 ---
// 게임의 전체 흐름이나 캐릭터의 현재 상태를 명확하게 구분하기 위해 사용합니다.
enum GameState { TITLE, PLAYING, SETTINGS, STAGE_CLEAR, GAME_OVER } // 메인 화면, 게임 중, 설정 화면, 클리어, 게임 오버

// 캐릭터가 현재 어떤 행동을 하고 있는지 판별하여 애니메이션 및 로직을 제어합니다.
enum CharacterState { IDLE, MOVE, ROLL, ATTACK, RELOAD } // 대기, 이동, 구르기, 공격, 재장전

// 게임에 존재하는 무기의 종류입니다.
enum WeaponType { NONE, PISTOL, ASSAULT_RIFLE, SHOTGUN, SNIPER } // 맨손, 권총, 돌격소총, 샷건, 저격총

// 보스 몬스터가 사용하는 공격 패턴의 종류입니다.
enum BossPattern { CIRCLE, RAPID, GRENADE } // 원형 탄막, 고속 기관총, 수류탄 투척

import processing.sound.*; // 사운드 처리를 위해 Processing Sound 라이브러리를 불러옵니다.

// --- 오디오 프로퍼티 시스템 (에셋 매니저 패턴) ---
// 문자열 대신 고유한 정수(int) ID를 사용하여 효과음을 아주 빠르고 효율적으로 관리합니다.
final int SFX_PISTOL_SHOT   = 0; // 권총 발사음
final int SFX_PISTOL_RELOAD = 1; // 권총 장전음
final int SFX_AR_SHOT       = 2; // 돌격소총 발사음
final int SFX_AR_RELOAD     = 3; // 돌격소총 장전음
final int SFX_SG_SHOT       = 4; // 샷건 발사음
final int SFX_SG_RELOAD     = 5; // 샷건 장전음
final int SFX_SR_SHOT       = 6; // 저격총 발사음
final int SFX_SR_RELOAD     = 7; // 저격총 장전음
final int SFX_EMPTY_CLICK   = 8; // 탄창이 비었을 때 나는 찰칵 소리

// 로드된 모든 사운드 파일을 담아두는 배열입니다. (위의 ID 값을 인덱스로 사용해 재생합니다)
SoundFile[] audioProperties;

// --- 게임 전역 (Global) 변수 ---
// 게임이 처음 켜졌을 때의 시작 상태를 타이틀 화면으로 설정합니다.
GameState currentGameState = GameState.TITLE;

// 스테이지, 총알, 파티클(이펙트)의 생성 및 삭제를 총괄하는 코어 관리자(Manager) 객체들입니다.
StageManager stageManager;
BulletManager bulletManager;
ParticleManager particleManager; 

// 플레이어가 조종하는 메인 캐릭터 객체입니다.
Character player;

// 화면에 계속해서 늘어나거나 줄어들 수 있는 개체들을 관리하기 위해 크기가 유동적으로 변하는 리스트(ArrayList)를 사용합니다.
ArrayList<Enemy> enemies = new ArrayList<Enemy>();         // 적 목록
ArrayList<WeaponDrop> drops = new ArrayList<WeaponDrop>(); // 바닥에 떨어진 무기(아이템) 목록
ArrayList<Obstacle> obstacles = new ArrayList<Obstacle>(); // 장애물(벽) 목록

// --- 카메라 및 맵(월드) 크기 설정 ---
// 카메라의 현재 X, Y 좌표와 캐릭터를 따라갈 때의 부드러운 정도(보간 수치)를 설정합니다.
float camX = 0, camY = 0;
float camEasing = 0.05;

// 플레이어가 실제로 돌아다닐 수 있는 맵 전체의 가로, 세로 픽셀 크기입니다.
float worldWidth = 2000, worldHeight = 2000;

// 마우스 좌클릭을 꾹 누르고 있는지 확인하여 자동 연사를 처리하기 위한 스위치입니다.
boolean isShooting = false;

// --- 이미지 리소스 (PImage) ---
// 바닥에 떨어져 있는 무기(아이템) 이미지들
PImage dropPistol, dropAR, dropShotgun, dropSniper;

// 캐릭터가 손에 들고 장착하고 있는 무기 이미지들
PImage equipPistol, equipAR, equipShotgun, equipSniper;

// 총알, 바닥 타일, 장애물 타일, 마우스 조준점 등 공통 환경 이미지들
PImage bulletImg; 
PImage bgTileImg;
PImage obsTileImg;
PImage crosshairImg;

// 플레이어, 일반 적, 보스 등 살아있는 개체들의 이미지
PImage playerImg, enemyImg, bossImg;

// --- 스테이지 클리어 UI 연출 변수 ---
// 엔딩 화면이 갑자기 나타나지 않고 서서히 밝아지게(페이드인) 만들기 위한 변수들입니다.
float clearTextAlpha = 0;          // 현재 글씨의 투명도 (0=투명, 255=완전 선명함)
float clearFadeSpeed = 3.0;        // 글씨가 선명해지는 속도
boolean clearFadeComplete = false; // 페이드인 연출이 끝났는지 확인하는 스위치

// --- UI 메뉴 레이아웃 좌표 ---
// 1920x1080 FHD 화면 비율에 맞춰 왼쪽 사이드바 메뉴가 그려질 위치와 기본 크기를 정의합니다.
float menuX = 0;
float menuY = 0;
float menuW = 450; 
float menuH = 1080;

void setup()
{
    // 1. 창 크기 및 렌더러 설정 (가장 먼저 실행되어야 함)
    size(1920, 1080, P2D);
    println("Step 1: Window Initialized");

    // 2. 이미지 에셋 로드
    dropPistol  = loadImage("drop_pistol.png");
    dropAR      = loadImage("drop_ar.png");
    dropShotgun = loadImage("drop_shotgun.png");
    dropSniper  = loadImage("drop_sniper.png");
    equipPistol  = loadImage("equip_pistol.png");
    equipAR      = loadImage("equip_ar.png");
    equipShotgun = loadImage("equip_shotgun.png");
    equipSniper  = loadImage("equip_sniper.png");
    bulletImg = loadImage("bullet.png");
    obsTileImg = loadImage("obstacle.png");
    bgTileImg = loadImage("bg_tile.png");
    playerImg = loadImage("player.png");
    enemyImg = loadImage("enemy.png");
    bossImg = loadImage("boss.png");
    crosshairImg = loadImage("cross.png");
    println("Step 2: Assets Loaded");

    // 3. 매니저 및 플레이어 초기화 (중복 제거됨!)
    bulletManager = new BulletManager(500);
    particleManager = new ParticleManager(300);
    
    // 월드 크기를 먼저 확정 짓고 플레이어 생성
    worldWidth = 2000; 
    worldHeight = 2000;
    player = new Character(worldWidth / 2, worldHeight / 2);
    player.pickUpWeapon(WeaponType.PISTOL);
    
    stageManager = new StageManager();
    println("Step 3: Managers Initialized");

    // 4. 오디오 시스템 초기화
    audioProperties = new SoundFile[9];
    audioProperties[SFX_PISTOL_SHOT]   = new SoundFile(this, "pistol_shot.wav");
    audioProperties[SFX_PISTOL_RELOAD] = new SoundFile(this, "pistol_reload.wav");
    audioProperties[SFX_AR_SHOT]       = new SoundFile(this, "ar_shot.wav");
    audioProperties[SFX_AR_RELOAD]     = new SoundFile(this, "ar_reload.wav");
    audioProperties[SFX_SG_SHOT]       = new SoundFile(this, "sg_shot.wav");
    audioProperties[SFX_SG_RELOAD]     = new SoundFile(this, "sg_reload.wav");
    audioProperties[SFX_SR_SHOT]       = new SoundFile(this, "sr_shot.wav");
    audioProperties[SFX_SR_RELOAD]     = new SoundFile(this, "sr_reload.wav");
    audioProperties[SFX_EMPTY_CLICK]   = new SoundFile(this, "empty_click.wav");
    println("Step 4: Audio Initialized");

    // 5. 첫 스테이지 데이터 빌드
    stageManager.initStage();
    currentGameState = GameState.TITLE;
    println("Step 5: Setup Complete. Game Starting...");
}

void draw()
{
    // --- 1. 배경 초기화 (UI 화면용) ---
    // 타이틀 화면이나 설정 화면일 경우, 이전 프레임의 UI 잔상을 지우기 위해 남색 배경을 덮어줍니다.
    if (currentGameState == GameState.TITLE || currentGameState == GameState.SETTINGS) 
    {
        background(10, 10, 25); 
    }

    // --- 2. 상태 머신(FSM) 렌더링 분기 ---
    // 현재 게임 상태에 따라 알맞은 화면 업데이트 및 렌더링 함수를 호출합니다.
    switch (currentGameState)
    {
        case TITLE:       drawTitleScreen(); break;
        case PLAYING:     updateAndDrawGameplay(); break;
        case SETTINGS:    drawSettingScreen(); break;
        case STAGE_CLEAR: drawStageClearScreen(); break;
        case GAME_OVER:   drawGameOverScreen(); break;
    }
    
    // --- 3. 동적 커서(마우스) 제어 로직 ---
    // 게임 플레이 중일 때는 마우스 화살표를 숨기고 커스텀 조준점(크로스헤어)을 최상단에 그립니다.
    if (currentGameState == GameState.PLAYING)
    {
        noCursor(); 
        drawCrosshair();
    }
    // 메뉴 화면 등 UI 조작이 필요할 때는 기본 마우스 화살표를 다시 보여줍니다.
    else
    {
        cursor(ARROW); 
    }
}

// --- 화면 상태(FSM) 렌더링 함수들 ---
void drawStageClearScreen()
{
    // 1. 우주 배경을 가장 먼저 그립니다.
    drawSpaceBackground();
    
    // 2. 화면 전체에 반투명한 검은색 사각형을 덮어서 배경을 어둡게(Dim) 만듭니다.
    rectMode(CORNER);
    noStroke();
    fill(0, 200);
    rect(0, 0, width, height);
    
    // 3. 텍스트가 서서히 나타나는 페이드인(Fade-in) 연출 로직입니다.
    if (clearTextAlpha < 255) 
    {
        clearTextAlpha += clearFadeSpeed; // 알파(투명도) 값을 조금씩 증가시킵니다.
    }
    else 
    {
        clearTextAlpha = 255; // 알파값이 최대치에 도달하면 고정합니다.
        clearFadeComplete = true; // 페이드인 연출이 끝났음을 시스템에 알립니다.
    }
    
    textAlign(CENTER, CENTER);
    
    // 4. 메인 텍스트의 그림자(Drop Shadow)를 그려서 입체감을 줍니다. (살짝 오른쪽 아래로 치우치게 배치)
    fill(0, clearTextAlpha);
    textSize(124);
    text("GAME CLEAR!", width / 2 + 5, height * 0.4 + 5);
    
    // 5. 메인 텍스트를 그립니다.
    fill(255, clearTextAlpha);
    textSize(120);
    text("GAME CLEAR!", width / 2, height * 0.4);
    
    // 6. 텍스트 페이드인 연출이 완전히 끝난 후에만 '메인 메뉴로 돌아가기' 버튼을 보여줍니다.
    if (clearFadeComplete) 
    {
        float btnW = 350;
        float btnH = 80;
        float btnX = (width - btnW) / 2; // 버튼이 화면 정중앙에 오도록 X 좌표를 계산합니다.
        float btnY = height * 0.75;
        
        // 엔진의 코어 UI 버튼 그리기 함수를 재사용합니다.
        drawMenuButton("MAIN MENU", btnX, btnY, btnW, btnH);
    }
}

void drawWorldBase()
{
    float tileSize = 128.0; // 타일 한 칸의 크기입니다.
    
    imageMode(CORNER);
    background(30); // 맵 타일이 깔리지 않은 바깥 빈 공간은 어두운 회색으로 칠합니다.

    // 화면 밖의 타일은 그리지 않도록(Culling), 현재 카메라 화면에 보이는 타일의 시작과 끝 인덱스만 계산합니다. (렉 방지를 위한 렌더링 최적화)
    int startCol = (int)max(0, camX / tileSize);
    int endCol = (int)min(worldWidth / tileSize, (camX + width) / tileSize + 1);
    
    int startRow = (int)max(0, camY / tileSize);
    int endRow = (int)min(worldHeight / tileSize, (camY + height) / tileSize + 1);

    // 계산된 화면 내의 타일 영역만 반복문을 돌며 타일 이미지를 그려줍니다.
    for (int col = startCol; col <= endCol; col++)
    {
        for (int row = startRow; row <= endRow; row++)
        {
            float drawX = col * tileSize;
            float drawY = row * tileSize;
            
            image(bgTileImg, drawX, drawY, tileSize, tileSize);
        }
    }
}

void drawGameOverScreen()
{
    // 핏빛 느낌의 어두운 붉은색 배경을 깔아줍니다.
    background(50, 0, 0);
    textAlign(CENTER, CENTER);
    
    // 게임 오버 메인 타이틀 텍스트
    fill(255, 50, 50); textSize(80); text("GAME OVER", width / 2, height / 2 - 50);
    
    // 마우스 클릭 시 재시작이 가능함을 알리는 안내 텍스트
    fill(255); textSize(24); text("Click to restart game", width / 2, height / 2 + 50);
}

// --- 게임 플레이 메인 루프 ---

void updateAndDrawGameplay()
{
    background(180); 
    
    // 카메라 트래킹 로직
    float targetX = player.x - width/2;
    float targetY = player.y - height/2;
    camX += (targetX - camX) * camEasing;
    camY += (targetY - camY) * camEasing;
    
    pushMatrix();
    translate(-camX, -camY);
    
    drawWorldBase();
    stageManager.update(); 
    
    for (Obstacle o : obstacles) o.render();
    for (int i = drops.size()-1; i >= 0; i--)
    {
        WeaponDrop d = drops.get(i);
        d.render();
        if (dist(player.x, player.y, d.x, d.y) < 40)
        {
            player.pickUpWeapon(d.weapon);
            drops.remove(i);
        }
    }
    
    if (isShooting) player.tryAttack();
    player.update();
    player.checkCollision(obstacles); 
    player.render();
    
    handleCombat();
    
    bulletManager.updateAndRender(worldWidth, worldHeight, obstacles);
    particleManager.updateAndRender();
    
    popMatrix(); // 카메라 해제
    player.renderUI();
    
    // --- [NEW] Stage Title UI Overlay ---
    if (stageManager.titleAlpha > 0)
    {
        textAlign(CENTER, CENTER);
        fill(0, stageManager.titleAlpha * 0.5);
        textSize(84);
        text("WORLD " + stageManager.worldNum + " - STAGE " + stageManager.stageNum, width/2 + 4, height/2 + 4);
        
        // Main Text
        fill(255, stageManager.titleAlpha);
        textSize(80);
        String msg = (stageManager.stageNum == 4) ? "FINAL BOSS" : "STAGE " + stageManager.worldNum + "-" + stageManager.stageNum;
        text(msg, width / 2, height / 2);
    }

    if (stageManager.transAlpha > 0)
    {
        noStroke();
        fill(0, stageManager.transAlpha); 
        rectMode(CORNER);
        rect(0, 0, width, height); 
    }
}

void drawTitleScreen()
{
    // 빛나는 우주 배경 애니메이션을 그립니다.
    drawSpaceBackground();

    // 왼쪽 메뉴 사이드바를 반투명한 남색으로 그립니다.
    noStroke();
    fill(20, 25, 45, 230);
    rect(menuX, menuY, menuW, height); // 화면 세로 전체 길이(1080)에 딱 맞게 채움

    // 사이드바 상단의 제작자 정보 텍스트
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(54);
    text("MADE BY", menuW / 2, 180); 

    fill(150, 200, 255);
    textSize(22);
    text("Hyeonseo Song", menuW / 2, 250);
    text("Jongwon Yoon", menuW / 2, 275);
    text("Nagyeong Yang", menuW / 2, 300);

    // 메뉴 화면 진입 버튼 2개를 그립니다.
    drawMenuButton("START", 85, 380, 280, 70);
    drawMenuButton("SETTING", 85, 480, 280, 70);

    // 오른쪽 빈 공간에 들어갈 메인 타이틀 게임 이름 텍스트
    float introCenterX = (width + menuW) / 2; // 오른쪽 빈 공간의 한가운데 정렬 기준선(X 좌표) 계산
    
    fill(255);
    textSize(72);
    text("DIGIPEN HUNTERS", introCenterX, 450);

    fill(180, 220, 255);
    textSize(28);
    text("DigiPen 19th", introCenterX, 550); 
}

void drawSettingScreen()
{
    // 설정 화면에서도 별자리 배경은 계속 돌아갑니다.
    drawSpaceBackground();

    noStroke();
    fill(20, 25, 45, 230);
    rect(menuX, menuY, menuW, height);

    fill(255);
    textAlign(CENTER, CENTER);
    textSize(50);
    text("SETTING", menuW / 2, 180);

    // 설정 관련 수치 텍스트 (더미 데이터)
    fill(180, 220, 255);
    textSize(24);
    text("Volume : 100%", menuW / 2, 320);
    text("Difficulty : Arcade Hard", menuW / 2, 390);

    // 타이틀로 다시 돌아가는 '뒤로가기' 버튼
    drawMenuButton("BACK", 85, 900, 280, 70);

    // 설정 화면 우측의 설명 텍스트 패널
    float introCenterX = (width + menuW) / 2;
    fill(255);
    textSize(48);
    text("Audio & Gameplay options", introCenterX, 500);

    fill(180, 220, 255);
    textSize(24);
    text("Engine Configuration Layer Active", introCenterX, 580);
}

void drawSpaceBackground()
{ 
    // 매 프레임마다 별의 위치가 랜덤하게 바뀌지 않도록 난수 시드를 고정시킵니다.
    randomSeed(10);
    noStroke();

    // 120개의 반짝이는 별(작은 원)을 화면 전체에 그립니다.
    for (int i = 0; i < 120; i++) 
    {
        float x = random(width);
        float y = random(height);
        float size = random(2, 5); 

        // frameCount와 삼각함수(sin) 파동을 결합하여 별이 서서히 밝아졌다 어두워지는 깜빡임(Pulsating) 효과를 만들어냅니다.
        float alpha = sin(frameCount * 0.05 + i) * 80 + 175;

        fill(255, alpha);
        ellipse(x, y, size, size);
    }
}

void drawMenuButton(String label, float x, float y, float w, float h) 
{
    // 현재 마우스 커서가 그려질 버튼 사각형 영역 안으로 들어왔는지 검사합니다.
    boolean hover = isMouseInsideBox(x, y, w, h);

    // 마우스가 버튼 위에 올라가 있으면(hover) 밝은 파란색, 아니면 원래의 어두운 파란색으로 칠합니다.
    if (hover) 
    {
        fill(80, 150, 255);
    } 
    else 
    {
        fill(45, 70, 120);
    }

    // 버튼의 외곽선(Stroke)을 그려줍니다.
    stroke(160, 210, 255);
    strokeWeight(2);
    rect(x, y, w, h, 12); // 사각형의 4개 모서리를 둥글게(반경 12) 깎아주어 부드러운 UI를 만듭니다.
    strokeWeight(1); // 이후에 그려질 다른 오브젝트에 영향을 주지 않도록 테두리 두께를 원상태(1)로 되돌립니다.

    // 버튼 중앙에 기능 이름(Label)을 적습니다.
    fill(255);
    textSize(26);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
}

// --- 마우스 충돌 판정 유틸리티 ---
// 마우스 커서의 현재 좌표(mouseX, mouseY)가 주어진 사각형(x, y, w, h) 영역 안에 있는지 검사합니다.
// UI 버튼을 클릭했는지, 마우스를 올렸는지(Hover) 확인할 때 아주 유용하게 쓰입니다.
boolean isMouseInsideBox(float x, float y, float w, float h) 
{
    return (mouseX >= x && mouseX <= x + w && mouseY >= y && mouseY <= y + h);
}

// --- 핵심 전투 및 충돌 로직 ---
// 매 프레임마다 적의 이동, 총알 충돌, 데미지 계산, 아이템 드랍 등을 총괄하는 아주 중요한 함수입니다.
void handleCombat()
{
    // 1. 적군 로직 업데이트 및 플레이어의 총알 맞음 판정
    // 리스트에서 적을 삭제할 때 순서가 꼬이지 않도록 반드시 뒤에서부터(역순으로) 순회합니다.
    for (int i = enemies.size() - 1; i >= 0; i--)
    {
        Enemy e = enemies.get(i);
        e.applySeparation(enemies);  // 적들이 서로 겹치지 않고 자연스럽게 흩어지도록 밀어냅니다 (Boids 알고리즘 응용).
        e.update(player);            // 적이 플레이어를 향해 이동하거나 공격 패턴을 실행합니다.
        e.checkCollision(obstacles); // 적이 벽(장애물)을 통과하지 못하게 막습니다.
        e.render();                  // 적을 화면에 그립니다.
        
        // 플레이어가 쏜 총알이 현재 순회 중인 적(e)에게 맞았는지 검사합니다.
        // 총알 매니저의 풀(Pool)을 순회하며 활성화된 총알만 확인합니다.
        for (int j = 0; j < bulletManager.poolSize; j++)
        {
            Bullet b = bulletManager.pool[j];
            
            // 원형 충돌 판정을 위한 거리 기준값 (적의 반지름 + 총알의 반지름)
            float collisionDist = e.size / 2 + b.sz / 2;
            
            // 총알이 활성화되어 있고, 플레이어가 쏜 것이며, 적과의 거리가 충돌 거리보다 가깝다면 (명중!)
            if (b.isActive && b.isPlayerBullet && dist(b.x, b.y, e.x, e.y) < collisionDist)
            {
                b.isActive = false; // 맞은 총알은 즉시 비활성화(삭제) 처리합니다.
                e.hp -= b.damage;   // 적의 체력을 총알의 데미지만큼 깎습니다.
                
                // [NEW] 적이 총알에 맞았을 때 붉은색 스파크(피) 파티클 효과를 터뜨려 타격감을 줍니다.
                particleManager.spawnSparks(b.x, b.y, color(255, 0, 0)); 
                
                // 적의 체력이 0 이하가 되어 죽었을 때의 처리
                if (e.hp <= 0)
                {
                    stageManager.enemiesAlive--; // 남은 적의 숫자를 하나 줄입니다.
                    
                    // 보스가 아닌 일반 적일 경우, 40% (0.4) 확률로 아이템을 떨어뜨립니다.
                    if (!(e instanceof Boss) && random(1) < 0.4) 
                    {
                        WeaponType[] lootPool = { WeaponType.PISTOL, WeaponType.ASSAULT_RIFLE, WeaponType.SHOTGUN, WeaponType.SNIPER };
                        // 드랍 가능한 무기 중 하나를 랜덤으로 골라 아이템 리스트에 추가합니다.
                        drops.add(new WeaponDrop(e.x, e.y, lootPool[(int)random(lootPool.length)]));
                    }
                    
                    enemies.remove(i); // 죽은 적을 화면(리스트)에서 완전히 삭제합니다.
                    break;             // 이 적은 이미 죽었으므로 남은 총알과 더 이상 충돌 검사를 할 필요가 없습니다 (최적화).
                }
            }
        }
    }

    // 2. 적군이 쏜 총알 vs 플레이어 맞음 판정
    for (int j = 0; j < bulletManager.poolSize; j++)
    {
        Bullet b = bulletManager.pool[j];
        
        // 총알이 활성화되어 있고, 적이 쏜 것이며, 플레이어와 가까이 닿았다면 (피격!)
        if (b.isActive && !b.isPlayerBullet && dist(b.x, b.y, player.x, player.y) < 25)
        {
            b.isActive = false; // 총알을 지웁니다.
            
            // [중요] 플레이어가 구르기(ROLL) 상태가 아닐 때만 데미지를 입습니다. (무적 판정, I-Frame 적용!)
            if (player.currentState != CharacterState.ROLL) 
            {
                player.hp -= b.damage;
                particleManager.spawnSparks(b.x, b.y, color(255, 0, 0)); // 플레이어가 피격당할 때도 붉은 스파크 연출
                
                // 체력이 0이 되면 게임 오버 화면으로 상태를 넘깁니다.
                if (player.hp <= 0) currentGameState = GameState.GAME_OVER;
            }
        }
    }
}

// --- 렌더링 최적화(Culling) 도우미 함수 ---
// 오브젝트(적, 총알, 아이템 등)가 현재 카메라에 잡히는 화면 안에 있는지 판별합니다.
// 화면 밖에 있는 것들은 렌더링(render)하지 않게 만들어 엔진의 프레임 속도(성능)를 폭발적으로 높여줍니다.
boolean isVisible(float objX, float objY, float objSize)
{
    // 화면 가장자리에서 오브젝트가 팝업되듯 갑자기 나타나거나 사라지는 것을 방지하기 위해 
    // 오브젝트 크기의 2배만큼 여유 공간(Margin)을 둡니다.
    float margin = objSize * 2.0; 
    
    return (objX + margin > camX && 
            objX - margin < camX + width && 
            objY + margin > camY && 
            objY - margin < camY + height);
}

// --- 사용자 입력 (키보드 및 마우스) 처리 ---

void mousePressed() 
{ 
    // 1. 타이틀(시작) 화면일 때
    if (currentGameState == GameState.TITLE) 
    {
        // START 버튼 클릭 (drawTitleScreen에 그려진 버튼 좌표와 동일하게 설정해야 합니다)
        if (isMouseInsideBox(85, 380, 280, 70)) 
        {
            stageManager.initStage();             // 스테이지를 초기화하고
            currentGameState = GameState.PLAYING; // 게임 플레이 화면으로 넘어갑니다.
        }

        // SETTING 버튼 클릭
        if (isMouseInsideBox(85, 480, 280, 70)) 
        {
            currentGameState = GameState.SETTINGS;
        }
    }
    // 2. 설정(SETTINGS) 화면일 때
    else if (currentGameState == GameState.SETTINGS)
    {
        // BACK 버튼 클릭
        if (isMouseInsideBox(85, 900, 280, 70)) 
        {
            currentGameState = GameState.TITLE; // 메인 타이틀로 돌아갑니다.
        }
    }
    // 3. 스테이지 클리어(STAGE_CLEAR) 화면일 때
    else if (currentGameState == GameState.STAGE_CLEAR) 
    {
        // 페이드인 연출이 완전히 끝난 후에만 클릭이 작동하도록 막아둡니다.
        if (clearFadeComplete) 
        {
            // 화면 정중앙에 위치한 MAIN MENU 버튼 좌표 계산
            float btnW = 350;
            float btnH = 80;
            float btnX = (width - btnW) / 2;
            float btnY = height * 0.75;
            
            // 버튼 영역을 클릭했다면
            if (isMouseInsideBox(btnX, btnY, btnW, btnH)) 
            {
                // 다음 클리어를 위해 페이드인 변수들을 0으로 초기화해 줍니다.
                clearTextAlpha = 0;
                clearFadeComplete = false;
                
                // 메인 타이틀 화면으로 돌아갑니다.
                currentGameState = GameState.TITLE;
            }
        }
    }
    // 4. 게임 오버(GAME_OVER) 화면일 때
    else if (currentGameState == GameState.GAME_OVER)
    {
        // 화면 아무 곳이나 클릭하면 플레이어의 체력을 꽉 채우고 기본 무기로 되돌린 뒤 처음(1-1)부터 다시 시작합니다.
        player.hp = player.maxHp;
        player.pickUpWeapon(WeaponType.PISTOL);
        stageManager.worldNum = 1;
        stageManager.stageNum = 1;
        stageManager.initStage();
        currentGameState = GameState.PLAYING;
    }
    // 5. 게임 플레이(PLAYING) 중일 때
    else if (currentGameState == GameState.PLAYING) 
    {
        // 마우스 버튼을 누르고 있으면 연사(Shooting) 스위치가 켜집니다.
        isShooting = true; 
    }
}

// 마우스를 뗐을 때: 연사를 중지하고, 단발/반자동 무기(권총, 샷건 등)의 방아쇠를 초기화하여 다음 발사를 준비합니다.
void mouseReleased() { isShooting = false; player.handleMouseInput(false); }

// 키보드를 눌렀을 때: 플레이어 객체에 해당 키(W, A, S, D, R, Space 등)가 눌렸다고(true) 전달합니다.
void keyPressed() { player.handleInput(key, true); }

// 키보드를 뗐을 때: 눌려있던 키가 해제되었다고(false) 플레이어에게 전달합니다.
void keyReleased() { player.handleInput(key, false); }

// --- 코어 엔진 클래스 모음 ---
// --- 스테이지 진행 및 스폰 관리자 ---
// --- 스테이지 진행 및 페이드 연출 관리자 ---
class StageManager
{
    int worldNum = 1, stageNum = 1, enemiesToSpawn, enemiesAlive, spawnCooldown;
    
    // --- Transition & UI Effects ---
    float transAlpha = 0;          // Black overlay transparency
    float titleAlpha = 0;          // Stage name text transparency
    boolean isTransitioning = false;
    boolean isFadeIn = false;      // Screen brightening phase
    boolean isTitleEffect = false; // Stage title display phase
    
    float fadeSpeed = 5.0;
    int titleTimer = 0;            // Duration for the text to stay on screen

    void initStage()
    {
        // Start with a black screen and trigger fade-in
        transAlpha = 255; 
        titleAlpha = 0;
        isTransitioning = true;
        isFadeIn = true; 
        isTitleEffect = false;
        titleTimer = 60; // Hold title for 1 second at 60fps
        
        drops.clear(); 
        enemies.clear();
        obstacles.clear();
        
        for (Bullet b : bulletManager.pool) b.isActive = false;
        for (Particle p : particleManager.pool) p.isActive = false;

        worldWidth = 2000 + (worldNum * 500); 
        worldHeight = 2000 + (worldNum * 500);
        player.x = worldWidth / 2; 
        player.y = worldHeight / 2;
        
        // Generate obstacles (Same as before)
        if (stageNum != 4)
        {
            int targetObsCount = min(40, 15 + (worldNum * 5));
            int attempts = 0;
            while (obstacles.size() < targetObsCount && attempts < 1500)
            {
                attempts++;
                float tw = random(100, 300), th = random(100, 300);
                float tx = random(200, worldWidth - 200 - tw), ty = random(200, worldHeight - 200 - th);
                boolean overlap = false;
                for (Obstacle o : obstacles) if (o.intersects(tx, ty, tw, th, 80.0)) overlap = true;
                if (dist(tx + tw/2, ty + th/2, worldWidth/2, worldHeight/2) < 400) overlap = true;
                if (!overlap) obstacles.add(new Obstacle(tx, ty, tw, th));
            }
        }

        enemiesAlive = 0;
        if (stageNum == 4) 
        { 
            enemiesToSpawn = 0; 
            enemies.add(new Boss(worldWidth / 2 + 600, worldHeight / 2)); 
            enemiesAlive = 1; 
        }
        else 
        { 
            enemiesToSpawn = 5 + (worldNum * 3) + (stageNum * 2); 
            spawnCooldown = 60; 
        }
    }

    void update()
    {
        if (!isTransitioning)
        {
            // Standard gameplay logic
            if (stageNum != 4 && enemiesToSpawn > 0)
            {
                spawnCooldown--;
                if (spawnCooldown <= 0)
                {
                    float a = random(TWO_PI);
                    enemies.add(new Enemy(player.x + cos(a) * 900, player.y + sin(a) * 900));
                    enemiesToSpawn--; enemiesAlive++; 
                    spawnCooldown = max(30, 90 - (worldNum * 10)); 
                }
            }
            else if (enemiesAlive <= 0 && enemiesToSpawn <= 0)
            {
                isTransitioning = true;
                isFadeIn = false; // Start Fade-out to black
            }
        }
        else 
        {
            // Transition State Machine
            if (!isFadeIn && !isTitleEffect) // Phase 1: Fade-out to black
            {
                transAlpha += fadeSpeed;
                if (transAlpha >= 255)
                {
                    transAlpha = 255;
                    if (stageNum == 4) { worldNum++; stageNum = 1; currentGameState = GameState.STAGE_CLEAR; }
                    else { stageNum++; initStage(); }
                }
            }
            else if (isFadeIn) // Phase 2: Fade-in (Brightening screen)
            {
                transAlpha -= fadeSpeed;
                if (transAlpha <= 0)
                {
                    transAlpha = 0;
                    isFadeIn = false;
                    isTitleEffect = true; // Trigger Phase 3: Show Title
                }
            }
            else if (isTitleEffect) // Phase 3: Stage Title Animation
            {
                if (titleTimer > 0) // Title Fading In & Holding
                {
                    titleAlpha += fadeSpeed * 2;
                    if (titleAlpha >= 255) { titleAlpha = 255; titleTimer--; }
                }
                else // Title Fading Out
                {
                    titleAlpha -= fadeSpeed;
                    if (titleAlpha <= 0)
                    {
                        titleAlpha = 0;
                        isTitleEffect = false;
                        isTransitioning = false; // Finally resume gameplay
                    }
                }
            }
        }
    }
}

// 모든 움직이는 객체(캐릭터, 적)의 가장 뼈대가 되는 부모 클래스
class Sprite { float x, y, dx, dy; void update() { x += dx; y += dy; } }

// --- 장애물(벽) 클래스 ---
class Obstacle
{
    float x, y, w, h; // 장애물의 좌표와 가로/세로 길이

    Obstacle(float tx, float ty, float tw, float th) 
    { 
        x = tx; 
        y = ty; 
        w = tw; 
        h = th; 
    }

    void render() 
    { 
        // 1. 컬링(Culling): 카메라 화면 밖(안 보이는 곳)에 있는 장애물은 렌더링을 생략합니다.
        if (x > camX + width || x + w < camX || y > camY + height || y + h < camY) return;

        imageMode(CORNER);
        float tileSize = 64.0; // 화면에 그려질 타일 무늬 한 칸의 크기

        // 2. 장애물 크기에 맞춰 타일 이미지를 이어 붙여서(Tiling) 그립니다.
        for (float dx = 0; dx < w; dx += tileSize)
        {
            for (float dy = 0; dy < h; dy += tileSize)
            {
                // 장애물 경계선을 넘어가지 않도록 남은 자투리 길이를 계산합니다.
                float drawW = min(tileSize, w - dx);
                float drawH = min(tileSize, h - dy);
                
                // 화면에 그려질 크기에 맞춰 원본 이미지에서 잘라낼 비율을 계산합니다.
                int srcW = (int)(obsTileImg.width * (drawW / tileSize));
                int srcH = (int)(obsTileImg.height * (drawH / tileSize));
                
                image(obsTileImg, x + dx, y + dy, drawW, drawH, 0, 0, srcW, srcH);
            }
        }
        
        // 3. 입체감을 주기 위해 장애물 겉에 어두운 테두리를 한 줄 그어줍니다.
        noFill(); 
        stroke(50); 
        strokeWeight(2);
        rect(x, y, w, h);
        strokeWeight(1);
    }

    // --- [복구 완료!] 점(Point) 기반 충돌 검사 ---
    // 총알(BulletManager)이 벽의 영역(사각형) 안에 들어왔는지 검사할 때 사용됩니다.
    boolean contains(float px, float py) 
    { 
        return (px > x && px < x + w && py > y && py < y + h); 
    }

    // --- 영역(AABB) 기반 충돌 검사 ---
    // 스테이지 시작 시, 맵에 장애물을 생성할 때 서로 너무 가깝게 겹치지 않도록 여유 공간(margin)을 두고 검사합니다.
    boolean intersects(float ox, float oy, float ow, float oh, float margin)
    {
        return (x - margin < ox + ow && 
                x + w + margin > ox && 
                y - margin < oy + oh && 
                y + h + margin > oy);
    }
}

class Character extends Sprite
{
    CharacterState currentState = CharacterState.IDLE; // 현재 캐릭터의 상태
    WeaponType currentWeapon = WeaponType.NONE;        // 들고 있는 무기 종류
    
    float hp = 100, maxHp = 100;
    int ammo = 0, maxAmmo = 0;
    int stateTimer = 0, rollCD = 0, fireCD = 0, reloadCD = 0;
    boolean kU, kD, kL, kR, triggerReady = true;

    Character(float tx, float ty) { x = tx; y = ty; }

    void update()
    {
        // 1. 유한 상태 기계(FSM) 로직 처리
        switch(currentState)
        {
            case IDLE: 
            case MOVE: 
                updateMovement(); 
                break;
            case ROLL: 
                stateTimer--; 
                // 구르기 시간이 끝나면 다시 기본(IDLE) 상태로 돌아갑니다.
                if(stateTimer <= 0) currentState = CharacterState.IDLE; 
                break;
            case RELOAD: 
                updateMovement(); // 장전 중에도 무빙(이동)은 가능하게 허용합니다.
                reloadCD--; 
                // 장전 타이머가 0이 되는 순간 탄창을 꽉 채우고 상태를 복구합니다.
                if(reloadCD <= 0) 
                { 
                    ammo = maxAmmo; 
                    currentState = CharacterState.IDLE; 
                } 
                break;
            case ATTACK: 
                updateMovement(); 
                currentState = CharacterState.IDLE; 
                break;
        }
        
        // 2. 물리 이동 연산(super.update) 및 쿨타임 감소 처리
        super.update();
        if (rollCD > 0) rollCD--;
        if (fireCD > 0) fireCD--;
    }

    void updateMovement()
    {
        float s = 5.0; // 이동 속도
        dx = (kL ? -s : (kR ? s : 0)); 
        dy = (kU ? -s : (kD ? s : 0));
        
        // 이동 중이라면 MOVE, 가만히 있으면 IDLE 상태로 자동 전환 (장전 중일 때는 예외)
        if (dx != 0 || dy != 0) currentState = (currentState == CharacterState.RELOAD) ? CharacterState.RELOAD : CharacterState.MOVE;
        else if (currentState != CharacterState.RELOAD) currentState = CharacterState.IDLE;
    }

    // [중요 수정됨] 캐릭터와 맵/장애물 간의 물리 충돌을 처리하는 함수
    void checkCollision(ArrayList<Obstacle> obs)
    {
        float r = 25.0; // 플레이어의 반지름 (50x50 이미지의 절반)
        
        // 1. 맵 밖으로 나가지 못하게 반지름만큼 여유를 두고 가둬둡니다.
        x = constrain(x, r, worldWidth - r); 
        y = constrain(y, r, worldHeight - r);
        
        for (Obstacle o : obs)
        {
            // 2. AABB 충돌 검사: 점(Point)이 아닌 원(Radius)을 기준으로 벽에 부딪혔는지 검사합니다.
            if (x + r > o.x && x - r < o.x + o.w && y + r > o.y && y - r < o.y + o.h)
            {
                // 부딪힌 4개의 면(상하좌우) 중 가장 얕게 파고든 곳을 찾아내 그 방향으로 밀어냅니다.
                float dL = abs((x + r) - o.x);
                float dR = abs((x - r) - (o.x + o.w));
                float dT = abs((y + r) - o.y);
                float dB = abs((y - r) - (o.y + o.h));
                
                float min = min(min(dL, dR), min(dT, dB));
                
                // 밀어낼 때도 반지름(r)을 더해주어 캐릭터의 겉면이 벽에 딱 붙게 만듭니다.
                if (min == dL) x = o.x - r; 
                else if (min == dR) x = o.x + o.w + r; 
                else if (min == dT) y = o.y - r; 
                else y = o.y + o.h + r;
            }
        }
    }

    void tryAttack()
    {
        // 1. 구르거나 장전 중일 때는 총을 쏠 수 없습니다. (방어 코드)
        if (currentWeapon == WeaponType.NONE || currentState == CharacterState.ROLL || currentState == CharacterState.RELOAD) return;
        if (fireCD > 0) return;

        // 2. 연사(Auto) 무기가 아닐 경우, 마우스를 뗐다가 다시 눌러야만 발사되게 만듭니다.
        boolean isAuto = (currentWeapon == WeaponType.ASSAULT_RIFLE);
        if (!isAuto && !triggerReady) return;

        // 3. 총알이 다 떨어졌을 때 빈 약실 소리(찰칵)를 내고 자동 장전으로 넘어갑니다.
        if (ammo <= 0)
        {
            fireCD = 15; 
            tryReload(); 
            if (!isAuto) triggerReady = false;
            return; 
        }

        // 4. 캐릭터와 마우스 커서 사이의 각도를 삼각함수(atan2)로 계산합니다.
        float angle = atan2((mouseY + camY) - y, (mouseX + camX) - x);

        // 5. 무기 종류에 맞춰 발사 쿨타임과 총알의 스펙(속도, 크기, 데미지)을 세팅합니다.
        switch (currentWeapon)
        {
            case PISTOL:        fireCD = 20; spawnB(angle, 15, 15, 15.0); break;
            case ASSAULT_RIFLE: fireCD = 6;  spawnB(angle + random(-0.05, 0.05), 20, 15, 8.0); break; // 샷건처럼 퍼지는 오차범위 추가
            case SHOTGUN:       fireCD = 45; for (int i = -2; i <= 2; i++) spawnB(angle + i * 0.15, 18, 12, 12.0); break; // 5발을 부채꼴로 동시 발사
            case SNIPER:        fireCD = 60; spawnB(angle, 40, 20, 100.0); break;
            case NONE:          break;
        }

        ammo--; // 총알 1발 소모
        playWeaponSound(currentWeapon, false); // 발사 사운드 재생
        if (!isAuto) triggerReady = false; // 단발 무기 발사 락(Lock)
    }

    // 총알 매니저를 호출해 실제로 화면에 총알 객체를 찍어내는 짧은 도우미 함수
    void spawnB(float a, float s, float sz, float dmg) { bulletManager.fireBullet(x, y, cos(a)*s, sin(a)*s, sz, dmg, true); }

    void tryRoll() 
    {
        // 쿨타임이 끝났을 때만 순간적으로 속도를 2.5배 뻥튀기하여 구릅니다.
        if (rollCD <= 0 && currentState != CharacterState.ROLL)
        { 
            currentState = CharacterState.ROLL; 
            stateTimer = 20; 
            rollCD = 60; 
            dx *= 2.5; 
            dy *= 2.5;
        } 
    }

    void tryReload()
    {
        // 장전 중이거나 굴러갈 때 중복 장전되는 것을 막습니다.
        if (currentWeapon == WeaponType.NONE || currentState == CharacterState.RELOAD || currentState == CharacterState.ROLL) return;
        
        // [중요 수정됨] 탄창이 이미 꽉 차있다면 장전 모션과 소리를 취소합니다. (무한 장전 방지)
        if (ammo == maxAmmo) return;

        currentState = CharacterState.RELOAD;

        // 무기 무게감에 따라 장전이 완료되는 프레임(시간)을 다르게 줍니다.
        switch (currentWeapon)
        {
            case PISTOL:        reloadCD = 170;  break; 
            case ASSAULT_RIFLE: reloadCD = 170;  break; 
            case SHOTGUN:       reloadCD = 50;   break; // 샷건은 한 발씩 넣는 기믹이므로 짧게 세팅
            case SNIPER:        reloadCD = 170;  break; 
            case NONE:          break;
        }

        playWeaponSound(currentWeapon, true); // 장전 사운드 재생
    }
  
    // 바닥의 무기를 주웠을 때 장착 무기를 바꾸고 최대 탄창을 재설정합니다.
    void pickUpWeapon(WeaponType w) 
    { 
        currentWeapon = w;  
        if (w == WeaponType.PISTOL) maxAmmo = 12; 
        else if (w == WeaponType.ASSAULT_RIFLE) maxAmmo = 30;  
        else if (w == WeaponType.SHOTGUN) maxAmmo = 6; 
        else if (w == WeaponType.SNIPER) maxAmmo = 5; 
        
        ammo = maxAmmo;
    }

    // 캐릭터와 들고 있는 무기를 화면에 그려냅니다.
    void render()
    {
        float angle = atan2((mouseY + camY) - y, (mouseX + camX) - x);
        
        pushMatrix();
        translate(x, y); // 캐릭터 좌표로 캔버스 원점 이동
        
        // 1. 캐릭터 몸통 렌더링
        pushMatrix();
        rotate(angle); // 마우스 방향으로 캐릭터 몸통 회전
        imageMode(CENTER);
        
        // 구를 때는 반투명하게, 장전할 때는 살짝 푸른빛이 돌게 틴트(색조) 효과를 줍니다.
        if (currentState == CharacterState.ROLL) tint(255, 150);
        else if (currentState == CharacterState.RELOAD) tint(150, 150, 255);
        
        image(playerImg, 0, 0, 50, 50); 
        noTint(); // 다른 이미지가 물들지 않게 틴트 즉시 해제
        popMatrix();
        
        // 2. 무기 렌더링
        if (currentWeapon != WeaponType.NONE)
        {
            pushMatrix();
            rotate(angle); 
            
            // 마우스가 캐릭터의 왼쪽(뒤)으로 넘어갈 때 총기 이미지가 위아래로 뒤집히지 않도록 반전시킵니다.
            if (abs(angle) > PI / 2.0) scale(1, -1);
            
            imageMode(CENTER);
            PImage img = equipPistol;
            float targetWidth = 35.0;
            float targetHeight = 15.0; 
            
            // 무기별로 이미지와 사이즈를 스위칭합니다.
            if (currentWeapon == WeaponType.ASSAULT_RIFLE) { img = equipAR; targetWidth = 65.0; targetHeight = 25.0; }
            else if (currentWeapon == WeaponType.SHOTGUN) { img = equipShotgun; targetWidth = 65.0; targetHeight = 20.0; }
            else if (currentWeapon == WeaponType.SNIPER) { img = equipSniper; targetWidth = 90.0; targetHeight = 22.0; }
            
            // 총이 캐릭터 몸 바깥으로 적당히 튀어나와 보이도록 좌표 보정 (targetWidth * 0.4)
            image(img, targetWidth * 0.4, 15, targetWidth, targetHeight);
            popMatrix();
        }
        
        popMatrix();
    }

    // 캐릭터의 체력, 총알 등 UI를 화면 좌표계에 고정하여 그립니다.
    void renderUI()
    {
        fill(255); 
        textSize(32); 
        textAlign(CENTER, TOP);
        
        // 스테이지 정보 표시
        if (stageManager.stageNum == 4) 
        { 
            fill(255, 50, 50); 
            text("WORLD " + stageManager.worldNum + " - BOSS STAGE", width / 2, 20);
        }
        else 
        { 
            text("STAGE " + stageManager.worldNum + " - " + stageManager.stageNum, width / 2, 20); 
            textSize(20); 
            text("Enemies Left: " + (stageManager.enemiesToSpawn + stageManager.enemiesAlive), width / 2, 60); 
        }

        // 좌측 상단 플레이어 HP 바 (비율에 맞춰 초록색 게이지가 줄어듦)
        fill(50); rect(20, 20, 200, 25); 
        fill(0, 255, 0); rect(20, 20, 200 * (hp / maxHp), 25);
        
        // 하단 중앙 무기 및 탄약 정보 표시
        fill(0); 
        textSize(24); 
        textAlign(CENTER, BOTTOM);
        
        // 총알이 없을 때 frameCount를 활용하여 붉은색으로 깜빡거리는(Blink) 위험 경고 효과
        if (ammo <= 0 && (frameCount % 30 < 15)) fill(255, 0, 0);
        else fill(255);
        
        text(currentWeapon + " | AMMO: " + ammo + "/" + maxAmmo, width / 2, height - 40);
        
        // 장전 중일 때 화면 한가운데에 시각적 피드백 제공
        if (currentState == CharacterState.RELOAD) 
        {
            fill(150, 150, 255);
            text("RELOADING...", width / 2, height / 2);
        }
    }

    // 키보드 입력을 이동 스위치(boolean)로 변환합니다. (대각선 동시 이동을 부드럽게 만들기 위함)
    void handleInput(char k, boolean p)
    { 
        if (k == 'w' || k == 'W') kU = p; 
        if (k == 's' || k == 'S') kD = p; 
        if (k == 'a' || k == 'A') kL = p; 
        if (k == 'd' || k == 'D') kR = p; 
        
        // 키를 눌렀을 때(p가 true일 때)만 특수 행동 실행
        if (p) 
        { 
            if (k == ' ') tryRoll(); 
            if (k == 'r' || k == 'R') tryReload(); 
        } 
    }

    // 마우스 버튼을 뗐을 때 단발성 무기의 방아쇠 락을 풀어줍니다.
    void handleMouseInput(boolean p) { if(!p) triggerReady = true; }
}

// --- 적 (Enemy) 시스템 클래스 ---
// 일반 몹들의 행동(AI), 충돌, 발사 로직을 담당합니다.
class Enemy extends Sprite
{
    float hp, maxHp = 50, size = 40; 
    int fireCD = 0; // 발사 쿨타임
    WeaponType currentWeapon; // 적이 들고 있는 무기
    
    Enemy(float tx, float ty) 
    { 
        x = tx; 
        y = ty; 
        hp = maxHp; 
        
        // 스폰될 때 4가지 무기 중 하나를 무작위로 들고 나옵니다.
        WeaponType[] w = { WeaponType.PISTOL, WeaponType.ASSAULT_RIFLE, WeaponType.SHOTGUN, WeaponType.SNIPER }; 
        currentWeapon = w[(int)random(w.length)]; 
    }

    // --- 무리 짓기 알고리즘 (Separation) ---
    // 여러 마리의 적이 스폰되었을 때, 한 점으로 뭉쳐서 겹치지 않게 서로를 밀어내는 Boids AI의 핵심 기술입니다.
    void applySeparation(ArrayList<Enemy> others)
    {
        float minDist = size + 5; // 적들끼리 유지해야 하는 최소 거리
        for (Enemy o : others) 
        { 
            // 자기 자신을 제외한 다른 적들만 검사합니다.
            if (o != this) 
            { 
                float d = dist(x, y, o.x, o.y); // 나와 상대방의 거리를 잽니다.
                
                // 거리가 최소 거리보다 가깝다면 (즉, 너무 가깝게 붙어 있다면)
                if (d < minDist && d > 0) 
                {   
                    // 상대방과 나 사이의 각도를 구해서 서로 반대 방향으로 아주 살짝(0.1배) 밀어냅니다.
                    float a = atan2(y - o.y, x - o.x); 
                    x += cos(a) * (minDist - d) * 0.1; 
                    y += sin(a) * (minDist - d) * 0.1;
                } 
            } 
        }
    }

    // --- 적 AI 메인 루프 ---
    void update(Character target) 
    {
        float d = dist(x, y, target.x, target.y); // Distance to player
        float a = atan2(target.y - y, target.x - x); // Angle to player
        
        // --- [NEW] Dynamic Attack Range based on Weapon Type ---
        // Snipers have a much longer engagement range (800px) compared to others (350px)
        float attackRange = (currentWeapon == WeaponType.SNIPER) ? 800.0 : 350.0;
        
        // If out of attack range, move toward the target
        if (d > attackRange) 
        { 
            dx = cos(a) * 2.2;
            dy = sin(a) * 2.2; 
        } 
        // If within attack range, stop and prepare to fire
        else 
        { 
            dx = 0; 
            dy = 0; 
            if(fireCD <= 0) fire(a); 
        } 
        
        // Apply physics and tick down the cooldown
        super.update();
        if (fireCD > 0) fireCD--; 
    }
    
    // --- 장애물 충돌 검사 (AABB 알고리즘) ---
    // 플레이어 충돌 검사와 마찬가지로, 원형(Radius) 반지름을 적용해 벽 파고듦 버그를 수정했습니다.
    void checkCollision(ArrayList<Obstacle> obs)
    { 
        float r = size / 2; // 적의 반지름
        
        for (Obstacle o : obs) 
        { 
            // 점(contains)이 아닌 원(r)의 바운딩 박스를 기준으로 벽과 겹쳤는지 검사합니다.
            if (x + r > o.x && x - r < o.x + o.w && y + r > o.y && y - r < o.y + o.h)
            {
                // 벽과 닿은 4면 중 가장 얕게 파고든 곳을 찾아 그 방향으로 밀어냅니다.
                float dL = abs((x+r)-o.x); 
                float dR = abs((x-r)-(o.x+o.w)); 
                float dT = abs((y+r)-o.y); 
                float dB = abs((y-r)-(o.y+o.h)); 
                
                float min = min(min(dL, dR), min(dT, dB)); 
                
                if (min == dL) x = o.x - r; 
                else if (min == dR) x = o.x + o.w + r; 
                else if (min == dT) y = o.y - r; 
                else y = o.y + o.h + r; 
            } 
        } 
    }
    
    // --- 적의 무기 발사 로직 ---
    void fire(float angle)
    {
        float speed = 6.0; // 적 총알의 기본 속도

        // 적이 들고 있는 무기에 따라 플레이어와 동일한 패턴(연사력, 펠릿 수 등)으로 총알을 쏩니다.
        if (currentWeapon == WeaponType.PISTOL)
        {
            fireCD = 50; 
            bulletManager.fireBullet(x, y, cos(angle) * speed, sin(angle) * speed, 15, 5.0, false);
        }
        else if (currentWeapon == WeaponType.ASSAULT_RIFLE)
        {
            fireCD = 15; 
            float spreadAngle = angle + random(-0.1, 0.1); // 돌격소총의 불규칙한 오차 범위
            bulletManager.fireBullet(x, y, cos(spreadAngle) * speed * 1.2, sin(spreadAngle) * speed * 1.2, 15, 3.0, false);
        }
        else if (currentWeapon == WeaponType.SHOTGUN)
        {
            fireCD = 100; 
            // 산탄총: 3발의 탄환을 부채꼴로 동시 발사합니다.
            for (int i = -1; i <= 1; i++)
            {
                float pelletAngle = angle + (i * 0.2);
                bulletManager.fireBullet(x, y, cos(pelletAngle) * speed * 0.9, sin(pelletAngle) * speed * 0.9, 12, 8.0, false);
            }
        }
        else if (currentWeapon == WeaponType.SNIPER)
        {
            fireCD = 150; 
            // 저격총: 발사 전 치명적임을 알리기 위해 엄청난 속도와 데미지를 줍니다.
            bulletManager.fireBullet(x, y, cos(angle) * speed * 2.5, sin(angle) * speed * 2.5, 20, 25.0, false);
        }
    }

    void render()
    {
        // 최적화: 카메라 밖으로 벗어난 적은 화면에 그리지 않습니다.
        if (!isVisible(x, y, size)) return;

        // [연출 기믹] 적이 저격총을 들고 있고 발사하기 직전(40프레임 전)일 때, 레이저 포인터 선을 그려서 플레이어에게 피할 타이밍을 알려줍니다.
        if (currentWeapon == WeaponType.SNIPER && fireCD < 40) 
        { 
            stroke(255, 0, 0, 150); 
            strokeWeight(2); 
            line(x, y, player.x, player.y); 
            noStroke(); 
        }

        // 항상 플레이어 방향을 바라보도록 각도를 계산합니다.
        float angle = atan2(player.y - y, player.x - x);
        
        pushMatrix();
        translate(x, y);
        
        // 1. 적의 몸통 그리기
        pushMatrix();
        rotate(angle); 
        imageMode(CENTER);
        image(enemyImg, 0, 0, 50, 50);
        popMatrix();
        
        // 2. 적이 들고 있는 무기 그리기 (플레이어의 무기 렌더링 코드와 거의 동일합니다)
        if (currentWeapon != WeaponType.NONE)
        {
            pushMatrix();
            rotate(angle);
            
            // 플레이어를 바라보는 방향이 등 뒤로 넘어갈 때 총기 이미지가 뒤집히지 않게 반전
            if (abs(angle) > PI / 2.0) scale(1, -1);
            
            imageMode(CENTER);
            PImage img = equipPistol;
            float targetWidth = 35.0;
            float targetHeight = 15.0; 
            
            if (currentWeapon == WeaponType.ASSAULT_RIFLE) { img = equipAR; targetWidth = 65.0; targetHeight = 25.0; }
            else if (currentWeapon == WeaponType.SHOTGUN) { img = equipShotgun; targetWidth = 65.0; targetHeight = 20.0; }
            else if (currentWeapon == WeaponType.SNIPER) { img = equipSniper; targetWidth = 90.0; targetHeight = 22.0; }
            
            image(img, size * 0.6, 15, targetWidth, targetHeight);
            popMatrix();
        }
        popMatrix(); 
        
        // 3. 적 머리 위에 작은 체력바 표시
        fill(255, 0, 0); 
        rect(x - size / 2, y - size / 2 - 15, size * (hp / maxHp), 5);
    }
}

// --- 보스 (Boss) 클래스 ---
// Enemy를 상속(extends)받아, 기본 적의 기능은 그대로 쓰면서 체력과 공격 패턴만 오버라이딩(덮어쓰기) 합니다.
class Boss extends Enemy
{
    BossPattern pattern = BossPattern.CIRCLE; // 현재 실행 중인 보스의 공격 패턴
    int patternTimer = 120; // 2초(120프레임)마다 패턴을 미친 듯이 바꿉니다.
    ArrayList<Grenade> grenades = new ArrayList<Grenade>(); // 3번 패턴용 수류탄 리스트
    float attackRange;

    Boss(float tx, float ty)
    {
        super(tx, ty); // 부모 클래스(Enemy)의 생성자를 호출해 기본 세팅을 마칩니다.
        size = 200; // 보스답게 충돌 크기를 200픽셀로 뻥튀기합니다.
        
        // 월드 레벨에 따라 체력이 배로 늘어납니다 (1월드=1500, 2월드=3000...)
        maxHp = 1500 * stageManager.worldNum;
        hp = maxHp;
        currentWeapon = WeaponType.NONE; // 일반 총을 쓰지 않고 고유 패턴만 씁니다.
        attackRange = 3000.0; // 맵 어디에 있든 공격이 닿습니다.
    }

    // --- 보스 AI 메인 루프 (오버라이딩) ---
    @Override
    void update(Character target)
    {
        super.update(target); // 기본 적들의 이동/발사 쿨다운 로직을 그대로 실행합니다.
        patternTimer--;

        // 2초마다 공격 패턴을 무작위(0, 1, 2)로 바꿔 플레이어를 압박합니다.
        if (patternTimer <= 0)
        {
            pattern = BossPattern.values()[(int)random(3)];
            patternTimer = 120; 
        }

        // 수류탄(Grenade) 패턴 시 생성된 폭탄들의 연산을 업데이트합니다.
        for (int i = grenades.size() - 1; i >= 0; i--)
        {
            Grenade g = grenades.get(i);
            g.update();

            // 터진(done) 폭탄이 일정 시간이 지나면 메모리(리스트)에서 지워줍니다.
            if (g.done && g.timer < -20)
            {
                grenades.remove(i);
            }
        }
    }

    // --- 보스 공격 패턴 (오버라이딩) ---
    // 보스의 패턴 스위치에 따라 완전히 다른 방식으로 탄막을 뿜어냅니다.
    @Override
    void fire(float angle)
    {
        switch (pattern)
        {
            case CIRCLE: // 1. 원형 탄막 (Bullet Hell)
            {
                fireCD = 50; 
                // 360도를 16조각으로 나눠서 엄청난 크기의 총알 파도를 사방으로 뿜어냅니다.
                for (int i = 0; i < 16; i++)
                {
                    float spreadAngle = i * PI / 8;
                    bulletManager.fireBullet(x, y, cos(spreadAngle) * 7, sin(spreadAngle) * 7, 20, 15, false);
                }
                break;
            }
            case RAPID: // 2. 초고속 기관총 (Minigun)
            {
                fireCD = 4; // 발사 쿨타임 4 (거의 1초에 15발씩 쏩니다)
                // 살짝 흩어지는 오차를 주면서 플레이어에게 미친 속도로 총알을 난사합니다.
                float rapidAngle = angle + random(-0.15, 0.15);
                bulletManager.fireBullet(x, y, cos(rapidAngle) * 12, sin(rapidAngle) * 12, 15, 12, false);
                break;
            }
            case GRENADE: // 3. 곡사포/수류탄 투척
            {
                fireCD = 70; 
                // 플레이어가 서 있는 현재 위치(x, y)에 수류탄 객체를 던집니다. (터질 때까지 시간이 걸림)
                grenades.add(new Grenade(x, y, player.x, player.y));
                break;
            }
        }
    }

    @Override
    void render()
    {
        if (!isVisible(x, y, size)) return;

        float angle = atan2(player.y - y, player.x - x);

        pushMatrix();
        translate(x, y);

        // --- 1. 거대한 보스 몸통 그리기 ---
        pushMatrix();
        rotate(angle);
        imageMode(CENTER);
        image(bossImg, 0, 0, 450, 200); // 450x200 사이즈의 거대한 전차(Boss) 이미지 
        popMatrix();

        // --- 2. 보스의 머리 위 체력바 ---
        // (참고: 보스전의 경우 화면 상단 전체를 덮는 UI용 체력바를 따로 만드는 것이 상용 게임의 정석입니다)
        fill(255, 0, 0);
        rect(-size / 2, -size / 2 - 25, size * (hp / maxHp), 10);

        popMatrix();

        // --- 3. 보스가 던진 수류탄들 그리기 ---
        for (Grenade g : grenades)
        {
            g.render();
        }
    }
}

// --- 보스 수류탄 (Grenade) 투척 시스템 ---
class Grenade extends Sprite
{
    float tx, ty; // 수류탄이 날아갈 최종 목표 좌표
    int timer = 90; // 터지기까지 걸리는 시간 (60프레임 = 1초, 즉 1.5초 뒤 폭발)
    boolean done = false; // 이미 터졌는지 확인하는 스위치

    Grenade(float startX, float startY, float targetX, float targetY)
    {
        x = startX;
        y = startY;
        tx = targetX;
        ty = targetY;
    }

    void update()
    {
        // 1. 아직 터지지 않았다면 목표 지점을 향해 부드럽게 날아갑니다 (선형 보간 비율 0.05 적용).
        if (!done)
        {
            x += (tx - x) * 0.05;
            y += (ty - y) * 0.05;
        }

        timer--;

        // 2. 타이머가 0이 되는 순간 폭발합니다!
        if (timer == 0)
        {
            done = true; // 터짐 상태로 변경 (렌더링 모양이 바뀝니다)

            // 3. 폭발 반경(120 픽셀) 안에 플레이어가 있는지 검사합니다.
            // [중요] 플레이어가 구르기(ROLL) 중일 때는 무적(I-frame) 판정을 받아 데미지를 입지 않습니다!
            if (dist(x, y, player.x, player.y) < 120 && player.currentState != CharacterState.ROLL)
            {
                player.hp -= 30; // 뼈아픈 30의 광역 데미지

                if (player.hp <= 0)
                {
                    currentGameState = GameState.GAME_OVER;
                }
            }
        }
    }

    void render()
    {
        // 터지기 전: 바닥에 붉은색 경고 원과 수류탄 본체를 그립니다.
        if (!done)
        {
            noFill();
            // 타이머가 줄어들수록 붉은색 원이 점점 옅어지는 효과 (map 함수 사용)
            stroke(255, 0, 0, map(timer, 0, 90, 255, 50));
            strokeWeight(2);
            
            // 타이머가 줄어들수록 원의 크기도 바깥에서 안쪽으로 쪼그라듭니다.
            float currentRadius = 240 * (1 - (float)timer / 90.0);
            ellipse(tx, ty, currentRadius, currentRadius);
            
            strokeWeight(1);
            
            // 짙은 초록색의 수류탄 본체
            fill(50, 100, 50);
            ellipse(x, y, 20, 20);
        }
        // 터진 후: 폭발 반경을 보여주는 거대한 주황색 불기둥을 그립니다.
        else
        {
            fill(255, 100, 0, 150);
            noStroke();
            ellipse(x, y, 240, 240); // 데미지 반경(120)의 2배(지름) 크기
        }
    }
}

// --- 개별 총알 (Bullet) 객체 ---
class Bullet extends Sprite
{
    float sz, damage; 
    boolean isActive = false; // 현재 화면에 날아다니고 있는지(true) 창고에 박혀있는지(false) 확인
    boolean isPlayerBullet = false; // 아군 총알인지 적군 총알인지 구분

    // 총알을 화면에 발사할 때 (풀에서 꺼내 쓸 때) 호출되는 초기화 함수
    void spawn(float tx, float ty, float tdx, float tdy, float tSz, float dmg, boolean p) 
    { 
        x = tx; 
        y = ty; 
        dx = tdx; 
        dy = tdy; 
        sz = tSz; 
        damage = dmg; 
        isPlayerBullet = p; 
        isActive = true; 
    }

    void render()
    {
        // 비활성화된(죽은) 총알은 그리지 않습니다. (최적화)
        if (!isActive) return;
        
        // 총알이 날아가는 방향(X, Y 속도)을 삼각함수로 계산하여 각도를 구합니다.
        float angle = atan2(dy, dx);
        
        pushMatrix();
        translate(x, y);
        rotate(angle); // 총알 이미지가 날아가는 방향을 쳐다보게 회전시킵니다.
        
        imageMode(CENTER);
        
        // 적군의 총알이면 눈에 띄게 붉은색 틴트를 입혀줍니다.
        if (!isPlayerBullet) { tint(255, 50, 50); }
        
        // 원본 총알 이미지의 가로세로 비율(Aspect Ratio)을 계산하여 찌그러지지 않게 그립니다.
        float aspect = (float)bulletImg.width / bulletImg.height * 0.5;
        
        image(bulletImg, 0, 0, sz * aspect, sz);
        
        noTint();
        popMatrix();
    }
}

// --- 총알 통합 관리자 (BulletManager - 핵심 최적화 클래스) ---
// [오브젝트 풀링(Object Pooling)] 총알이 나갈 때마다 메모리를 새로 할당(new)하면 쓰레기 수집기(GC) 때문에 렉이 걸립니다.
// 그래서 게임이 켜질 때 배열에 총알 500개를 미리 다 만들어두고, 필요할 때마다 꺼내 쓰고 다 쓰면 다시 창고에 넣는 방식을 사용합니다.
class BulletManager
{
    Bullet[] pool; // 500개의 총알을 담아둘 거대한 배열(풀)
    int poolSize;

    BulletManager(int n)
    {
        poolSize = n;
        pool = new Bullet[n];
        
        // 게임 시작 시점에 메모리에 총알 객체들을 미리 한꺼번에 만들어둡니다.
        for (int i = 0; i < n; i++)
        {
            pool[i] = new Bullet();
        }
    }

    // 누군가 총을 쐈을 때 호출되는 함수
    void fireBullet(float x, float y, float dx, float dy, float sz, float dmg, boolean p)
    {
        // 500개의 총알 창고를 뒤져서, 현재 '비활성화(isActive == false)' 상태인 첫 번째 빈 총알을 찾습니다.
        for (Bullet b : pool)
        {
            if (!b.isActive)
            {
                // 빈 총알을 찾아 좌표와 데미지를 덮어씌우고 화면에 발사(활성화)합니다.
                b.spawn(x, y, dx, dy, sz, dmg, p);
                return; // 한 발을 쐈으니 바로 함수를 종료합니다.
            }
        }
    }

    void updateAndRender(float w, float h, ArrayList<Obstacle> obs)
    {
        for (Bullet b : pool)
        {
            if (!b.isActive) continue; // 창고에 대기 중인 빈 총알은 계산하지 않습니다. (성능 향상)

            b.update(); // 총알 이동

            // 1. 화면(월드) 밖으로 아예 날아간 총알은 비활성화하여 창고로 반납합니다.
            if (b.x < 0 || b.x > w || b.y < 0 || b.y > h)
            {
                b.isActive = false;
            }

            // 2. 맵에 배치된 장애물(벽)과의 충돌 검사
            for (Obstacle o : obs)
            {
                if (o.contains(b.x, b.y))
                {
                    b.isActive = false; // 벽에 맞은 총알도 즉시 비활성화(삭제)
                    // 총알이 벽에 튀었으므로 노란색 스파크(파티클) 효과를 터뜨립니다.
                    particleManager.spawnSparks(b.x, b.y, color(255, 255, 0)); 
                    break; // 이미 부딪혔으니 다른 벽은 검사할 필요 없습니다.
                }
            }

            // 충돌 검사 후에도 살아남은 총알만 화면에 그립니다.
            if (b.isActive)
            {
                b.render();
            }
        }
    }
}

// --- 파티클 (타격/폭발 효과 이펙트) 시스템 ---

class Particle extends Sprite 
{
    int life;     // 남은 수명
    int maxLife;  // 원래 설정된 전체 수명
    color c;      // 파티클 색상 (적 피격=빨강, 벽 피격=노랑 등)
    boolean isActive = false;

    void spawn(float tx, float ty, float tdx, float tdy, color tc, int tLife)
    {
        x = tx;
        y = ty;
        dx = tdx;
        dy = tdy;
        c = tc;
        life = tLife;
        maxLife = tLife;
        isActive = true;
    }

    void update()
    {
        if (!isActive) return;

        super.update(); // 파티클 이동

        // 파티클이 공기 저항(Drag)을 받아 점점 느려지도록 속도에 0.9를 계속 곱해줍니다.
        dx *= 0.9;
        dy *= 0.9;

        life--; // 매 프레임 수명이 깎입니다.

        // 수명이 다 되면 화면에서 완전히 지워줍니다 (재활용 대기 상태).
        if (life <= 0)
        {
            isActive = false;
        }
    }

    void render()
    {
        if (!isActive) return;

        // 수명이 줄어들수록 파티클이 점점 투명하게 사라지는 페이드아웃 효과 (map 사용)
        float currentAlpha = map(life, 0, maxLife, 0, 255);
        fill(red(c), green(c), blue(c), currentAlpha);
        noStroke();
        ellipse(x, y, 6, 6); // 자그마한 6픽셀짜리 파편을 그립니다.
    }
}

// 총알과 마찬가지로 성능을 위해 파티클도 '오브젝트 풀링' 방식으로 미리 수백 개를 만들어두고 관리합니다.
class ParticleManager 
{
    Particle[] pool;
    int poolSize;

    ParticleManager(int size)
    {
        poolSize = size;
        pool = new Particle[poolSize];
        
        for (int i = 0; i < size; i++)
        {
            pool[i] = new Particle();
        }
    }

    // 총알이 어딘가에 맞았을 때, 사방으로 튀는 파편(스파크) 8개를 한 번에 생성합니다.
    void spawnSparks(float x, float y, color c) 
    {
        int particlesToSpawn = 8; // 한 번에 생성할 파편 개수

        for (Particle p : pool)
        {
            if (!p.isActive)
            {
                // 파편이 튀어나갈 무작위 각도(0~360도)와 무작위 속도를 설정합니다.
                float angle = random(TWO_PI);
                float speed = random(2.0, 6.0);
                int lifespan = (int)random(10, 20); // 금방 사라지도록 짧은 수명 부여
                
                // 풀에서 잠자고 있던 파티클을 깨워 스파크 모양으로 세팅합니다.
                p.spawn(x, y, cos(angle) * speed, sin(angle) * speed, c, lifespan);
                
                particlesToSpawn--;
                
                // 8개를 다 만들었다면 반복문을 즉시 종료합니다.
                if (particlesToSpawn <= 0) break;
            }
        }
    }

    void updateAndRender()
    {
        for (Particle p : pool)
        {
            p.update();
            p.render();
        }
    }
}

// --- 바닥에 떨어진 무기(아이템) 객체 ---
class WeaponDrop extends Sprite
{
    WeaponType weapon; // 이 객체가 어떤 종류의 무기를 품고 있는지 저장합니다.

    // 아이템이 맵에 생성될 때 좌표와 무기 종류를 받아 초기화합니다.
    WeaponDrop(float x1, float y1, WeaponType w)
    {
        x = x1;
        y = y1;
        weapon = w;
    }

    void render()
    {
        imageMode(CENTER);
        
        // 1. 컬링(Culling) 최적화: 아이템이 카메라 화면 밖으로 나가면 렌더링을 생략합니다.
        // 여유 공간(Margin)을 90으로 넉넉하게 주어 화면 끝에서 이미지가 잘리는 현상을 막습니다.
        if (!isVisible(x, y, 90.0)) return;
        
        // 2. 무기 종류에 따른 이미지와 기준 가로 크기(Width) 설정
        PImage img = dropPistol; // 기본값은 권총 이미지
        float targetWidth = 35.0; // 권총의 기본 가로 렌더링 크기
        
        // 조건문을 통해 무기 종류에 맞는 이미지와 크기로 스위칭(교체)합니다.
        if (weapon == WeaponType.ASSAULT_RIFLE) { img = dropAR; targetWidth = 65.0; }
        else if (weapon == WeaponType.SHOTGUN) { img = dropShotgun; targetWidth = 65.0; }
        else if (weapon == WeaponType.SNIPER) { img = dropSniper; targetWidth = 90.0; }
        
        // 3. 종횡비(Aspect Ratio)를 활용한 찌그러짐 방지 연산
        // 원본 이미지의 가로/세로 비율을 구한 뒤, 우리가 설정한 targetWidth에 비례하도록 세로(Height)를 맞춥니다.
        float aspect = (float)img.width / img.height;
        float targetHeight = targetWidth / aspect;
        
        // 계산된 비율대로 바닥에 무기 이미지를 그려줍니다.
        image(img, x, y, targetWidth, targetHeight);
    }
}

// --- 오디오 매핑 (도우미) 함수 ---
// 게임 로직(무기 종류, 장전 여부)을 오디오 시스템이 알아들을 수 있는 숫자 ID(int)로 번역해 주는 역할입니다.
void playWeaponSound(WeaponType weapon, boolean isReloading)
{
    int targetAudioId = -1; // 기본값을 -1(잘못된 ID)로 두어 에러를 방지합니다.

    // 1. 장전 중일 때의 사운드 ID 매핑
    if (isReloading)
    {
        switch (weapon)
        {
            case PISTOL:        targetAudioId = SFX_PISTOL_RELOAD; break;
            case ASSAULT_RIFLE: targetAudioId = SFX_PISTOL_RELOAD;     break;
            case SHOTGUN:       targetAudioId = SFX_SG_RELOAD;     break;
            case SNIPER:        targetAudioId = SFX_PISTOL_RELOAD;     break;
            case NONE:          break; // 맨손일 때는 소리가 나지 않습니다.
        }
    }
    // 2. 사격 중일 때의 사운드 ID 매핑
    else
    {
        switch (weapon)
        {
            case PISTOL:        targetAudioId = SFX_PISTOL_SHOT; break;
            case ASSAULT_RIFLE: targetAudioId = SFX_AR_SHOT;     break;
            case SHOTGUN:       targetAudioId = SFX_SG_SHOT;     break;
            case SNIPER:        targetAudioId = SFX_SR_SHOT;     break;
            case NONE:          break;
        }
    }

    // 매핑된 ID가 정상적인 값(!= -1)이라면, 실제 오디오 재생 함수로 ID를 넘겨줍니다.
    if (targetAudioId != -1) playAudio(targetAudioId);
}

// --- 커스텀 조준점(크로스헤어) 렌더링 함수 ---
void drawCrosshair()
{
    imageMode(CENTER);
    
    // 마우스의 현재 좌표(mouseX, mouseY)를 따라다니도록 조준점 이미지를 60x60 크기로 그립니다.
    image(crosshairImg, mouseX, mouseY, 60, 60); 
}

// --- 통합 오디오 재생기 (에셋 매니저) ---
// 외부에서 숫자 ID만 던져주면 알아서 배열을 뒤져 사운드를 틀어주는 핵심 엔진 함수입니다.
void playAudio(int audioId)
{
    // [중요한 방어 코드]
    // 1. audioId가 0보다 크거나 같은지 (음수 인덱스 방지)
    // 2. audioId가 배열의 전체 크기보다 작은지 (배열 초과 오류 방지)
    // 3. 해당 배열 칸에 실제로 소리 파일이 들어있는지 (NullPointerException 방지)
    if (audioId >= 0 && audioId < audioProperties.length && audioProperties[audioId] != null)
    {
        audioProperties[audioId].play(); // 모든 안전검사를 통과했다면 소리를 재생합니다!
    }
}
