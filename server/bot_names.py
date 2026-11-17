"""Short, safe, present-day Chinese game nicknames for local NPCs."""
from __future__ import annotations

import hashlib
import random


# Everyday-style nicknames: food, moods, small habits, light wordplay and a
# few Latin-letter handles. No celebrity names, brands, slurs or symbols that
# depend on special fonts.
BOT_NAMES = (
    "芝士奶盖", "不吃香菜", "今天也要早睡", "小熊软糖", "柠檬不萌", "草莓味的风",
    "一只小咸鱼", "奶茶续命中", "周末不加班", "晚风很温柔", "西瓜最中间", "橘子汽水",
    "躺平但没完全躺", "熬夜冠军", "芋泥波波", "可乐加冰", "早八困难户", "螺蛳粉爱好者",
    "椰子冻", "布丁也会累", "吃饱了再说", "摸鱼小能手", "快乐肥宅水", "云朵棉花糖",
    "一颗糖不够", "月亮不营业", "星星打瞌睡", "鸽子精本精", "电量百分之一", "已读不回",
    "在线等挺急的", "别催在路上", "下次一定", "我不是菜鸡", "带飞求带", "单排上分",
    "峡谷养猪户", "野区散步", "补刀全靠运气", "辅助也想C", "中单不让", "打野来帮我",
    "这波我的", "稳住能赢", "再来亿把", "手感来了", "开局送一血", "逆风翻盘",
    "团战躲草丛", "偷塔专业户", "大招没好", "闪现撞墙", "回城被打断", "背锅侠",
    "小白兔奶糖", "抹茶红豆", "黑糖珍珠", "海盐芝士", "焦糖玛奇朵", "冰美式不加糖",
    "青提茉莉", "桃桃乌龙", "杨枝甘露", "烤红薯", "糖炒栗子", "关东煮",
    "麻辣烫加辣", "锅包肉", "小笼包", "煎饼果子", "热干面", "肉夹馍",
    "阿七", "小鹿", "十一", "阿北", "小周", "江江", "木木", "知夏", "南栀", "北笙",
    "清欢", "时屿", "林深", "沐晴", "听雨", "野草莓", "白桃", "初雪", "晚星", "微光",
    "momo", "Lucky", "Coco", "Kiki", "Mia酱", "Leo同学", "Aki", "Yuki", "Ryan", "Echo",
    "Nova", "Luna", "Zero", "Kai", "Jojo", "Max同学", "Bobo", "Nana", "Toto", "Lily",
    "猫猫队长", "狗勾不咬人", "仓鼠在跑轮", "企鹅滑倒了", "柯基短腿", "橘猫十斤",
    "布偶猫主子", "二哈拆家", "水獭搓手", "小浣熊", "考拉抱树", "熊猫眼",
    "兔子不吃胡萝卜", "刺猬软软", "海豹拍肚皮", "鸭鸭冲", "小黄鸭", "鲸鱼会唱歌",
    "鱼丸粗面", "咖喱鱼蛋", "一碗米线", "虾饺皇", "蛋挞控", "叉烧包",
    "今天不想上班", "明天再学习", "期末全靠蒙", "论文还没写", "图书馆占座", "考研人",
    "社恐但话多", "间歇性努力", "持续性摆烂", "精神状态良好", "情绪稳定", "佛系玩家",
    "运气守恒", "抽卡非酋", "欧皇附体", "十连保底", "保底歪了", "又是蓝光",
    "晨跑三公里", "健身第一天", "瑜伽垫", "骑行党", "羽毛球搭子", "篮球打不进",
    "听歌循环", "耳机常驻", "吉他初学者", "钢琴八级", "会做饭的人", "厨房杀手",
    "地铁站台", "末班公交", "通勤两小时", "楼下便利店", "深夜食堂", "路边摊",
    "雨天收伞", "晴天晒被子", "秋天的第一杯", "冬天吃火锅", "夏天吹空调", "春日野餐",
    "可颂", "贝果", "司康", "提拉米苏", "舒芙蕾", "千层",
    "宇宙超级无敌", "外星来的", "地球打工人", "火星移民", "银河漫游", "卫星信号弱",
    "WiFi满格", "流量不够用", "充电五分钟", "手机没电了", "截图大师", "表情包库",
    "小透明", "路人甲", "隐藏大佬", "萌新报到", "老玩家回归", "退坑又回来",
    "不想起名字", "名字被占了", "随便取一个", "这名字好长啊", "叫我小李", "就叫阿呆",
)


def bot_name_for_uid(uid: str) -> str:
    """Choose once per local bot UID; previews and selection stay consistent."""
    digest = hashlib.sha256(str(uid).encode("utf-8")).digest()
    return BOT_NAMES[int.from_bytes(digest[:8], "big") % len(BOT_NAMES)]


def sample_bot_names(rng: random.Random, count: int) -> list[str]:
    """Choose distinct nicknames for one persisted arena batch."""
    if not 0 <= count <= len(BOT_NAMES):
        raise ValueError("invalid local bot name count")
    return rng.sample(BOT_NAMES, count)
