//
//  TestViewController.m
//  RecordAudio
//
//  Created by 赵铭 on 16/9/27.
//  Copyright © 2016年 zm. All rights reserved.
//

#import "SecondViewController.h"
#import "ZMAudioRecorderUtil.h"
#import "ZMAudioPlayerUtil.h"
#import "ZMAudioManager.h"
#import "CustomCellModel.h"
#import "CustomCell.h"
@interface SecondViewController ()<UITableViewDelegate, UITableViewDataSource, ZMAudioManagerDelegate>
@property (nonatomic, strong) UITableView * tableView;
@property (nonatomic, strong) NSMutableArray * datasource;
@property (nonatomic, strong) CustomCellModel * previousSelectedModel;
@property (nonatomic, strong) NSTimer * metesTimer;
@property (nonatomic, strong) UIImageView * recoredAnimationView;
@property (nonatomic, copy) NSArray *voiceMessageAnimationImages;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _voiceMessageAnimationImages = @[@"VoiceSearchFeedback001",@"VoiceSearchFeedback002",@"VoiceSearchFeedback003",@"VoiceSearchFeedback004",@"VoiceSearchFeedback005",@"VoiceSearchFeedback006",@"VoiceSearchFeedback007",@"VoiceSearchFeedback008",@"VoiceSearchFeedback009",@"VoiceSearchFeedback010",@"VoiceSearchFeedback011",@"VoiceSearchFeedback012",@"VoiceSearchFeedback013",@"VoiceSearchFeedback014",@"VoiceSearchFeedback015",@"VoiceSearchFeedback016",@"VoiceSearchFeedback017",@"VoiceSearchFeedback018",@"VoiceSearchFeedback019",@"VoiceSearchFeedback020"];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height -44) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"CustomCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"cell"];
    [self.view addSubview:self.tableView];
    _recoredAnimationView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    _recoredAnimationView.center = self.view.center;
    [self.view addSubview:_recoredAnimationView];
    UIToolbar * toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 44, [UIScreen mainScreen].bounds.size.width, 44)];
    [self.view addSubview:toolbar];
    [toolbar layoutIfNeeded];

    UIButton * button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 0, 100, 30);
    button.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2, 22);
    [button setTitle:@"开始录音" forState:UIControlStateNormal];
    [toolbar addSubview:button];
    [button addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(touchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [button addTarget:self action:@selector(touchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [button addTarget:self action:@selector(touchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [button addTarget:self action:@selector(touchDragInside:) forControlEvents:UIControlEventTouchDragInside];
    [button addTarget:self action:@selector(touchDragOutside:) forControlEvents:UIControlEventTouchDragOutside];
    
    _datasource = @[].mutableCopy;
    [ZMAudioManager shareInstance].delegate = self;
    // Do any additional setup after loading the view.
}

#pragma mark -- UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _datasource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    CustomCellModel * model = _datasource[indexPath.row];
    if (model.isPlaying) {
        [cell.playImageView startAnimating];
    }
    else{
        [cell.playImageView stopAnimating];
    }
    if (model.aDuration > 0) {
        cell.timeLabel.text = [NSString stringWithFormat:@"录音时长：%ld'", (long)model.aDuration];
    }
    return cell;
}


#pragma mark -- UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    CustomCellModel * model = _datasource[indexPath.row];
    if ([[ZMAudioManager shareInstance] isPlaying]) {
        if (model == _previousSelectedModel) {//选中的是正在播放的语音
            model.isPlaying = NO;
            [[ZMAudioManager shareInstance] stopPlaying];
        }
        else{
            _previousSelectedModel.isPlaying = NO;
            model.isPlaying = YES;
            _previousSelectedModel = model;
            [[ZMAudioManager shareInstance] stopPlaying];
            [self playAudioWithModel:model];
        }
    }
    else{
        _previousSelectedModel = model;
        _previousSelectedModel.isPlaying = YES;
        [self playAudioWithModel:model];
    }
}

- (void)playAudioWithModel:(CustomCellModel *)model{
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.tableView reloadData];
    [[ZMAudioManager shareInstance] enableProximitySensor];
    [[ZMAudioManager shareInstance] playAudioWithPath:model.audioPath completion:^(NSError *error) {
        [[ZMAudioManager shareInstance] disableProximitySensor];
        _previousSelectedModel.isPlaying = NO;
        [self.tableView reloadData];

    }];
}

#pragma mark -- Action
//开始录音
- (IBAction)touchDown:(id)sender {
    [[ZMAudioManager shareInstance] startRecordingWithFileName:[NSString stringWithFormat:@"%f.wav", [[NSDate date] timeIntervalSince1970]] completion:^(NSError *error) {
        if (error) {
            
        }else{
            _metesTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(setVoiceImage) userInfo:nil repeats:YES];
        }
    }];
}

- (IBAction)touchUpInside:(id)sender {
    NSLog(@"%s", __func__);
    [[ZMAudioManager  shareInstance] stopRecordingWithType:ZMAudioRecordeAMRType completion:^(NSString *recordPath, NSInteger aDuration, NSError *error) {
        if (error) {
            UIAlertView *a = [[UIAlertView alloc] initWithTitle:@"error" message:error.domain delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
            [a show];
            [_metesTimer invalidate];
            _recoredAnimationView.hidden = YES;
            
        }else{
            CustomCellModel * model = [[CustomCellModel alloc] init];
            model.audioPath = recordPath;
            model.aDuration = aDuration;
            [_metesTimer invalidate];
            _recoredAnimationView.hidden = YES;
            [_datasource addObject:model];
            [_tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_datasource.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
    }];
}

- (IBAction)touchUpOutside:(id)sender {
    [_metesTimer invalidate];
    _recoredAnimationView.hidden = YES;

}

- (IBAction)touchDragEnter:(id)sender {
//    _label.text = @"手指上划，取消录音";
//    NSLog(@"%s", __func__);
    
}

- (IBAction)touchDragExit:(id)sender {
//    _label.text = @"松开手指，取消录音";
//    NSLog(@"%s", __func__);
    
}

- (IBAction)touchDragInside:(id)sender {
    NSLog(@"%s", __func__);
    
}
- (IBAction)touchDragOutside:(id)sender {
    NSLog(@"%s", __func__);
}

- (void)setVoiceImage{
    _recoredAnimationView.hidden = NO;
    double voiceSound = [[ZMAudioManager shareInstance] peekRecorderVoiceMeter];
    int index = voiceSound*[_voiceMessageAnimationImages count];
    if (index >= [_voiceMessageAnimationImages count]) {
        _recoredAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages lastObject]];
    } else {
        _recoredAnimationView.image = [UIImage imageNamed:[_voiceMessageAnimationImages objectAtIndex:index]];
    }
//    if (0 < voiceSound <= 0.05) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback001"]];
//    }else if (0.05<voiceSound<=0.10) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback002"]];
//    }else if (0.10<voiceSound<=0.15) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback003"]];
//    }else if (0.15<voiceSound<=0.20) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback004"]];
//    }else if (0.20<voiceSound<=0.25) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback005"]];
//    }else if (0.25<voiceSound<=0.30) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback006"]];
//    }else if (0.30<voiceSound<=0.35) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback007"]];
//    }else if (0.35<voiceSound<=0.40) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback008"]];
//    }else if (0.40<voiceSound<=0.45) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback009"]];
//    }else if (0.45<voiceSound<=0.50) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback010"]];
//    }else if (0.50<voiceSound<=0.55) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback011"]];
//    }else if (0.55<voiceSound<=0.60) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback012"]];
//    }else if (0.60<voiceSound<=0.65) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback013"]];
//    }else if (0.65<voiceSound<=0.70) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback014"]];
//    }else if (0.70<voiceSound<=0.75) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback015"]];
//    }else if (0.75<voiceSound<=0.80) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback016"]];
//    }else if (0.80<voiceSound<=0.85) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback017"]];
//    }else if (0.85<voiceSound<=0.90) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback018"]];
//    }else if (0.90<voiceSound<=0.95) {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback019"]];
//    }else {
//        [_recoredAnimationView setImage:[UIImage imageNamed:@"VoiceSearchFeedback020"]];
//    }
}
#pragma mark -- ZMDeviceManagerDelegate
- (void)proximitySensorChanged:(BOOL)isCloseToUser
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (isCloseToUser)
    {
        //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    [audioSession setActive:YES error:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
