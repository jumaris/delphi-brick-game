unit brickgame;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, DB, ADODB, hsframeA, InputName, winForm, dialog,
  WinSkinData, Buttons;

type
  // ש��
  BrickButton = class(TSpeedButton)
  public
    heart, reward: integer; // Ѫ������Ʒ
    backGround: TImage;
    procedure contacted;
    procedure setColor;
    constructor create(AOwner: Tcomponent); override;
    destructor destroy; override;
  end;

  // ��
  ballButton = class(TSpeedButton)
  public
    // x�ٶȺ�y�ٶ�
    ballSpeedx, ballSpeedy: integer;
    constructor create(AOwner: Tcomponent); override;
    // �����ײ
    procedure checkContact(var X: integer; var Y: integer);
    // �ƶ�
    procedure move;
    destructor destroy; override;
  end;

  // �����˶�״̬
  BoardMoveStatus = (up, down, stop);
  // ��Ϸ״̬
  GameStatus = (init, inGame, pause, dead, load, win, dbError, allOver,
    unkonwn);

  TMainForm = class(TForm)
    // ��Ϸ���
    gamePanel: TPanel;
    // ����
    board: TButton;
    // ��֡����ʱ��
    frameControl: TTimer;
    // ״̬
    statusText: TLabel;
    // ado����
    cnnSqlite: TADOConnection;
    // �߷ְ�ť
    highScoreButton: TButton;
    // ado��ѯ
    sQry: TADOQuery;
    // ��������
    scoreLabel: TLabel;
    // �ؿ�����
    Stage: TLabel;
    // ʣ��ש������
    brickleftlabel: TLabel;
    Button1: TButton;
    SpeedButton1: TSpeedButton;
    ButtonBackground: TImage;
    // ����¼�����Ϸ������ƶ������Ƶ����ƶ�״̬��
    procedure gamePanelMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: integer);
    // �����ƶ�
    procedure moveBoard;
    // ��ʼ��
    procedure initGame;
    // �����ƶ�
    procedure ballsmove;
    // ����
    procedure gamedead;
    // ���عؿ�
    function loadStage(stageName: string): boolean;
    // ��Ϸ״̬������
    procedure load(stageName: string);
    // �ͷ���Ϸ����
    procedure freeStageRes;
    // �����Ƿ��ཻ���ж��Ƿ���ײ��
    function isRecInteracted(rectX, rectY, rectWidth, rectHeight, objX, objY,
      objWidth, objHeight: integer): boolean;
    // �ػ����
    procedure drawScore;
    // ����ש��
    procedure createBrick(X, Y, w, h, ht, rwd: integer);
    // ״̬�л�
    procedure switchStatus(curStatus, nextStatus: GameStatus);
    // ��֡
    procedure frameControlTimer(Sender: TObject);
    // ��������Ϸ��壨��������״̬��
    procedure gamePanelEnter(Sender: TObject);
    // ����뿪��Ϸ��壨�رտ���״̬��
    procedure gamePanelExit(Sender: TObject);
    procedure statusTextClick(Sender: TObject);
    procedure highScoreButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    // �Ƿ�����
    function checkDead: boolean;
    // �Ƿ�Ӯ��
    function checkWin: boolean;
    procedure Button1Click(Sender: TObject);
    procedure rePaintBricks;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  // ����ƶ�״̬
  bms: BoardMoveStatus = BoardMoveStatus.stop;
  // ��ǰ��Ϸ״̬
  gs: GameStatus = GameStatus.init;
  // ��һ����Ϸ״̬
  lastStatus: GameStatus = GameStatus.unkonwn;
  // �����Կ���flag
  canControl: boolean = false;
  // ����ٶ�
  boardSpeed: integer = 4;
  // ��
  ball: ballButton;
  // ����
  score: integer = 0;
  // ��ͣ
  timerpause: boolean = false;
  // ��Ϸ��״̬
  subStatus: integer = 0;
  // ��Ϸ�ؿ�
  stageCount: integer = 1;
  // �ؿ����ƣ�Ϊ��Ӧ�Զ���ؿ���
  stageName: string;
  // ʣ��ש����
  brickLeft: integer;
  // ������
  ballCount: integer;

implementation

{$R *.dfm}

procedure BrickButton.contacted;
begin
  heart := heart - 1;
  score := score + 1;
  setColor;
  if heart = 0 then
    free;
end;

procedure TMainForm.rePaintBricks;
var
  i: integer;
  br: BrickButton;
begin
  for i := 0 to ComponentCount - 1 do
  begin
    if Components[i] is BrickButton then
    begin
      br := BrickButton(Components[i]);
      br.setColor;
    end;
  end;
end;

procedure TMainForm.createBrick(X, Y, w, h, ht, rwd: integer);
var
  brick: BrickButton;
begin
  brick := BrickButton.create(self);
  brick.parent := gamePanel;
  brick.Left := X;
  brick.Top := Y;
  brick.width := w;
  brick.height := h;
  brick.heart := ht;
  brick.reward := rwd;
end;

procedure BrickButton.setColor;
var
  pic: TRect;
begin
  pic.Left := 1;
  pic.right := width - 1;
  pic.Top := 1;
  pic.Bottom := height - 1;
  case heart of
    1:
      begin
        canvas.Brush.color := clred;
        canvas.FillRect(pic);
      end;
    2:
      begin
        canvas.Brush.color := clblue;
        canvas.FillRect(pic);
      end;
    3:
      begin
        canvas.Brush.color := clyellow;
        canvas.FillRect(pic);
      end;
    4:
      begin
        canvas.Brush.color := clAqua;
        canvas.FillRect(pic);
      end;
  end;
end;

constructor BrickButton.create(AOwner: Tcomponent);
begin
  inherited create(AOwner);
  self.Transparent := true;
  brickgame.brickLeft := brickgame.brickLeft + 1;
end;

destructor BrickButton.destroy;
begin
  brickgame.brickLeft := brickgame.brickLeft - 1;
  inherited destroy;
end;

constructor ballButton.create(AOwner: Tcomponent);
begin
  inherited create(AOwner);
  self.width := 10;
  self.height := 10;
  brickgame.ballCount := brickgame.ballCount + 1;
end;

destructor ballButton.destroy;
begin
  brickgame.ballCount := brickgame.ballCount - 1;
  inherited destroy;
end;

procedure ballButton.move;
var
  tempTop, tempLeft: integer;
begin
  tempTop := Top + ballSpeedy;
  tempLeft := Left + ballSpeedx;
  checkContact(tempLeft, tempTop);
  if tempLeft < brickgame.MainForm.board.Left +
    brickgame.MainForm.board.width then
    if brickgame.MainForm.board.Top < tempTop + height then
      if brickgame.MainForm.board.Top > tempTop -
        brickgame.MainForm.board.height then
      begin
        tempLeft := brickgame.MainForm.board.Left +
          brickgame.MainForm.board.width;
        ballSpeedx := -ballSpeedx;
        case bms of
          BoardMoveStatus.up:
            ballSpeedy := ballSpeedy - 1;
          BoardMoveStatus.down:
            ballSpeedy := ballSpeedy + 1;
        end;
      end;
  if tempTop < 0 then
  begin
    tempTop := 0;
    ballSpeedy := -ballSpeedy;
  end;
  if parent <> nil then
    if tempTop + height > parent.height then
    begin
      tempTop := parent.height - height;
      ballSpeedy := -ballSpeedy;
    end;
  if parent <> nil then
    if tempLeft + width > parent.width then
    begin
      tempLeft := parent.width - width;
      ballSpeedx := -ballSpeedx;
    end;
  Top := tempTop;
  Left := tempLeft;
  if tempLeft + width < 0 then
  begin
    free;
  end;
end;

// ������ʱ����������ײ
procedure ballButton.checkContact(var X: integer; var Y: integer);
var
  i, xOff, yOff, xNow, yNow: integer;
  af: double;
  br: BrickButton;
  isContact: boolean;
begin
  if X <> Left then
    af := (Y - Top) / (X - Left);
  if Left < X then
  begin
    for xNow := Left to X do
    begin
      yNow := Y + round((xNow - X) * af);
      for i := brickgame.MainForm.ComponentCount - 1 downto 0 do
      begin
        br := nil;
        if (brickgame.MainForm.Components[i] is BrickButton) then
        begin
          isContact := false;
          br := BrickButton(brickgame.MainForm.Components[i]);
          isContact := brickgame.MainForm.isRecInteracted(xNow, yNow, width,
            height, br.Left, br.Top, br.width, br.height);
          if isContact then
          begin
            X := xNow;
            Y := yNow;
            if ballSpeedx < 0 then
              xOff := br.Left + br.width - X
            else
              xOff := X - br.Left;
            if br <> nil then
            begin
              if ballSpeedy < 0 then
                yOff := br.Top + br.height - Y
              else
                yOff := Y - br.Top;
              if ballSpeedy = 0 then
              begin
                ballSpeedx := -ballSpeedx;
                X := br.Left - br.width;
                Y := yNow + round((X - xNow) * af);
              end
              else if xOff / abs(ballSpeedx) > yOff / abs(ballSpeedy) then
              begin
                ballSpeedy := -ballSpeedy;
              end
              else
              begin
                ballSpeedx := -ballSpeedx;
                X := br.Left - br.width;
                Y := yNow + round((X - xNow) * af);
              end;
              br.contacted;
              exit;
            end;
          end;
        end;
      end;
    end;
  end
  else if Left > X then
  begin
    for xNow := Left downto X do
    begin
      yNow := Y + round((xNow - X) * af);
      for i := brickgame.MainForm.ComponentCount - 1 downto 0 do
      begin
        br := nil;
        if (brickgame.MainForm.Components[i] is BrickButton) then
        begin
          isContact := false;
          br := BrickButton(brickgame.MainForm.Components[i]);
          isContact := brickgame.MainForm.isRecInteracted(xNow, yNow, width,
            height, br.Left, br.Top, br.width, br.height);
          if isContact then
          begin
            X := xNow;
            Y := yNow;
            if ballSpeedx < 0 then
              xOff := br.Left + br.width - X
            else
              xOff := X - br.Left;
            if ballSpeedy < 0 then
              yOff := br.Top + br.height - Y
            else
              yOff := Y - br.Top;
            if br <> nil then
            begin
              if ballSpeedy = 0 then
              begin
                ballSpeedx := -ballSpeedx;
                X := br.Left + br.width;
                Y := yNow + round((X - xNow) * af);
              end
              else if xOff / abs(ballSpeedx) > yOff / abs(ballSpeedy) then
              begin
                ballSpeedy := -ballSpeedy;
              end
              else
              begin
                ballSpeedx := -ballSpeedx;
                X := br.Left + br.width;
                Y := yNow + round((X - xNow) * af);
              end;
              br.contacted;
              exit;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
  newBall: ballButton;
begin
  newBall := ballButton.create(self);
  newBall.parent := gamePanel;
  newBall.Top := 50;
  newBall.Left := 300;
  newBall.ballSpeedx := 5;
  newBall.ballSpeedy := 1;
end;

procedure TMainForm.ballsmove;
var
  i: integer;
  ball: ballButton;
begin
  for i := ComponentCount - 1 downto 0 do
  begin
    if Components[i] is ballButton then
    begin
      ball := ballButton(Components[i]);
      ball.move;
    end;
  end;
end;

function TMainForm.checkDead: boolean;
begin
  if ballCount = 0 then
    switchStatus(gs, GameStatus.dead)
end;

function TMainForm.checkWin: boolean;
begin
  if brickLeft = 0 then
    switchStatus(gs, GameStatus.win);
end;

function TMainForm.isRecInteracted(rectX, rectY, rectWidth, rectHeight, objX,
  objY, objWidth, objHeight: integer): boolean;
begin
  if ((rectX + rectWidth > objX) and (rectX < objX + objWidth) and
      (rectY + rectHeight > objY) and (rectY < objY + objHeight)) then

    result := true
  else
    result := false;
end;

procedure TMainForm.freeStageRes;
var
  i: integer;
begin
  case subStatus of
    0:
      begin
        for i := ComponentCount - 1 downto 0 do
          if (Components[i] is BrickButton) or (Components[i] is ballButton)
            then
          begin
            Components[i].free;
          end;
        subStatus := subStatus + 1;
      end;
  end;
end;

procedure TMainForm.load(stageName: string);
var
  isLoadSucceed: boolean;
begin
  try
    isLoadSucceed := loadStage(stageName) except on e: exception
    do
    begin
      switchStatus(gs, dbError);
      exit;
    end;
  end;
  if isLoadSucceed then
    switchStatus(gs, inGame)
  else
    switchStatus(gs, allOver);
end;

function TMainForm.loadStage(stageName: string): boolean;
var
  icount, i: integer;
begin
  try
    if cnnSqlite.Connected = false then
      cnnSqlite.open;
    if sQry.Active then
      sQry.Close;
    sQry.sql.clear;
    sQry.sql.text := 'select * from stage where stageName =' + stageName;
    sQry.open;
    icount := sQry.RecordCount;
    for i := 0 to icount - 1 do
    begin
      createBrick(sQry.FieldByName('xpos').AsInteger,
        sQry.FieldByName('ypos').AsInteger,
        sQry.FieldByName('width').AsInteger,
        sQry.FieldByName('height').AsInteger,
        sQry.FieldByName('heart').AsInteger,
        sQry.FieldByName('reward').AsInteger);
      sQry.Next;
    end;
  finally
    cnnSqlite.Close;
  end;
  if icount = 0 then
    result := false
  else
    result := true;
end;

procedure TMainForm.switchStatus(curStatus, nextStatus: GameStatus);
begin
  subStatus := 0;
  if nextStatus = GameStatus.dbError then
  begin
    if dialogForm = nil then
      dialogForm := TdialogForm.create(self);
    dialogForm.DialogText.caption := '���ݶ�ȡ���������ļ�ȱʧ';
    gs := GameStatus.dbError;
    dialogForm.show;
  end;
  if curStatus = GameStatus.win then
  begin
    if nextStatus = GameStatus.init then
    begin
      winforma.Close;
      stageCount := stageCount + 1;
      gs := GameStatus.init;
    end;
  end;
  if curStatus = GameStatus.inGame then
  begin
    if nextStatus = GameStatus.dead then
    begin
      statusText.caption := '��Ϸ����';
      if inputNameDialog = nil then
        inputNameDialog := TInputNameDialog.create(self);
      inputNameDialog.show;
      gs := GameStatus.dead;
    end
    else if nextStatus = GameStatus.win then
    begin
      statusText.caption := 'ʤ��';
      if winforma = nil then
        winforma := TwinFormA.create(self);
      gs := GameStatus.win;
      winforma.show;
    end;
  end;

  if curStatus = GameStatus.init then
  begin
    if nextStatus = GameStatus.inGame then
    begin
      statusText.caption := '��Ϸ��';
      gs := GameStatus.inGame;
    end
    else if nextStatus = GameStatus.load then
    begin
      statusText.caption := '������';
      gs := GameStatus.load;
    end;
  end;

  if curStatus = GameStatus.load then
  begin
    if nextStatus = GameStatus.inGame then
    begin
      statusText.caption := '��Ϸ��';
      gs := GameStatus.inGame;
    end
    else if nextStatus = allOver then
    begin
      statusText.caption := '����������йؿ���';
      if winforma = nil then
      begin
        winforma := TwinFormA.create(self);
      end;
      gs := GameStatus.allOver;
      winforma.show;
    end;

  end;

  if curStatus = GameStatus.dead then
    if nextStatus = GameStatus.init then
    begin
      statusText.caption := '��Ϸ��';
      gs := GameStatus.init;
    end;
  if curStatus = GameStatus.inGame then
    if nextStatus = GameStatus.pause then
    begin
      statusText.caption := '��ͣ';
      gs := GameStatus.pause;
    end;
  if curStatus = GameStatus.pause then
    if nextStatus = GameStatus.inGame then
    begin
      statusText.caption := '��Ϸ��';
      gs := GameStatus.inGame;
    end;
  if curStatus = GameStatus.allOver then
    if nextStatus = GameStatus.init then
    begin
      stageCount := 1;
      statusText.caption := '��ʼ��';
      gs := GameStatus.init;
    end;
  lastStatus := curStatus;
end;

procedure TMainForm.gamedead;
begin ;
  stageCount := 1;
  stageName := intToStr(stageCount);
end;

procedure TMainForm.initGame;
var
  i: integer;
begin
  statusText.caption := '��ʼ��';
  boardSpeed := 4;
  score := 0;
  ballCount := 0;
  brickLeft := 0;
  board.Top := gamePanel.height div 2 - board.height div 2;
  stageName := intToStr(stageCount);
  for i := ComponentCount - 1 downto 0 do
  begin
    if (Components[i] is BrickButton) or (Components[i] is ballButton) then
      Components[i].free;
  end;
  ball := ballButton.create(self);
  ball.parent := gamePanel;
  ball.Top := 50;
  ball.Left := 300;
  ball.ballSpeedx := 5;
  ball.ballSpeedy := 1;
  switchStatus(gs, GameStatus.load);
end;

procedure TMainForm.moveBoard;
begin
  if not canControl then
    exit;
  case bms of
    BoardMoveStatus.up:
      if board.Top > 0 then
        board.Top := board.Top - boardSpeed;
    BoardMoveStatus.down:
      if board.Top + board.height < gamePanel.height then
        board.Top := board.Top + boardSpeed;
    BoardMoveStatus.stop:
      ;
  end;
end;

procedure TMainForm.highScoreButtonClick(Sender: TObject);
begin
  if highScoreForm = nil then
    highScoreForm := ThighScoreForm.create(self);
  highScoreForm.show;
  highScoreForm.qeuryHighScore;
  switchStatus(gs, GameStatus.pause);
end;

procedure TMainForm.drawScore;
begin
  scoreLabel.caption := 'score:' + intToStr(score);
  brickleftlabel.caption := 'ʣ��ש�飺' + intToStr(brickLeft);
  Stage.caption := '��' + stageName + '��';
end;

procedure TMainForm.statusTextClick(Sender: TObject);
begin
  if gs = GameStatus.dead then
    gs := init;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin ;
end;

procedure TMainForm.frameControlTimer(Sender: TObject);
begin
  if timerpause then
    exit;
  case gs of
    GameStatus.init:
      begin
        drawScore;
        initGame;
      end;
    GameStatus.win:
      begin
        freeStageRes;
      end;
    GameStatus.inGame:
      begin
        rePaintBricks;
        moveBoard;
        ballsmove;
        drawScore;
        checkWin;
        checkDead;
      end;
    GameStatus.dead:
      begin
        gamedead;
        freeStageRes;
      end;
    GameStatus.pause:
      ;
    GameStatus.load:
      load(stageName);
  end;

end;

procedure TMainForm.gamePanelEnter(Sender: TObject);
begin
  canControl := true;
end;

procedure TMainForm.gamePanelExit(Sender: TObject);
begin
  canControl := false;
end;

procedure TMainForm.gamePanelMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: integer);
begin

  if Y > board.Top + board.height then
    bms := BoardMoveStatus.down
  else if Y < board.Top then
    bms := BoardMoveStatus.up
  else
    bms := BoardMoveStatus.stop

end;

end.