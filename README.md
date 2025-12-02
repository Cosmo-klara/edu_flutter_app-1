# 高考志愿填报建议系统

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
</div>

## 技术栈

- **前端框架**: Flutter 3.16+
- **开发语言**: Dart
- **状态管理**: Provider / Riverpod
- **UI设计**: Material Design 3
- **API 服务**: ngrok tunnel (https://marlyn-unalleviative-annabel.ngrok-free.dev)

## 项目结构

> [!NOTE]
>
> 主体代码都在/lib文件夹中

```
flutter_app/
├── analysis_options.yaml          # 代码分析配置
├── assets/
│   └── images/                     # 图片资源
├── lib/
│   ├── main.dart                   # 应用入口
│   └── src/
│       ├── app.dart                # 应用主体
│       ├── services/
│       │   ├── api_client.dart     # API 客户端封装
│       │   └── api_exception.dart  # API 异常处理
│       ├── theme/
│       │   └── app_theme.dart      # 主题配置
│       ├── screens/
│       │   ├── auth/
│       │   │   └── auth_screen.dart        # 认证页面
│       │   └── home/
│       │       ├── home_shell.dart         # 主页框架
│       │       ├── pages/
│       │       │   ├── analysis_page.dart      # 分析页面
│       │       │   ├── college_page.dart       # 院校页面
│       │       │   ├── dashboard_page.dart     # 仪表盘页面
│       │       │   ├── heat_page.dart          # 热度页面
│       │       │   ├── info_page.dart          # 高考页面
│       │       │   ├── profile_page.dart       # 个人资料页面
│       │       │   └── recommend_page.dart     # 推荐页面
│       │       └── widgets/
│       │           └── immersive_header.dart   # 沉浸式头部组件
│       └── widgets/
│           ├── section_card.dart               # 区块卡片组件
│           ├── stat_chip.dart                  # 统计标签组件
│           ├── tag_chip.dart                   # 标签组件
│           └── timeline_item.dart              # 时间线项目组件
└── pubspec.yaml                    # 依赖配置
```

## 已接入的后端接口

### 1. 用户认证接口

#### 注册
- **接口**: `POST /auth/register`
- **状态**: ✅ 已接入
- **使用位置**: `auth_screen.dart`

#### 登录
- **接口**: `POST /auth/login`
- **状态**: ✅ 已接入
- **使用位置**: `auth_screen.dart`


### 2. 院校查询接口

#### 院校列表（分页）
- **接口**: `GET /colleges?page={page}&pageSize={pageSize}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 全国院校标签页

#### 院校筛选
- **接口**: `GET /colleges?province={province}&is985={0|1}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 筛选功能

#### 院校详情
- **接口**: `GET /colleges/{collegeCode}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 院校详情弹窗

#### 院校历年录取数据
- **接口**: `GET /colleges/{collegeCode}/admissions?province={province}&year={year}`
- **状态**: ✅ 已接入
- **使用位置**: `college_page.dart` - 历年录取标签页

### 3. 成绩管理接口

···

### 4. 高中录取记录接口

#### 查询高中录取记录
- **接口**: `GET /school-enrollment?schoolName={schoolName}&graduationYear={year}`
- **状态**: ✅ 已接入 【不完善】
- **使用位置**: `college_page.dart` - 高中录取标签页

## 接口认证说明

### Token 获取
用户登录成功后，后端返回 JWT token，前端需要保存并在后续请求中使用。

### Token 使用
需要认证的接口必须在请求头中添加：
```
Authorization: Bearer {token}
```

### Token 管理
- Token 存储在 `AuthScope` 中
- 通过 `AuthScope.of(context).session.token` 获取
- 在 `api_client.dart` 中自动添加到请求头

## 数据本地存储

### 成绩记录
- **存储方式**: 本地内存存储（临时）
- **位置**: `info_page.dart` - `_localScores`
- **说明**: 当前版本使用本地存储，待后端接口完善后切换到云端存储

### 收藏功能
- **存储方式**: 本地内存存储（临时）
- **位置**: `college_page.dart` - `_favoriteCollegeIds`
- **说明**: 待收藏接口开发后接入后端


## 快速开始

### 环境要求

- Flutter SDK 3.16 或更高版本
- Dart SDK 3.0 或更高版本
- iOS 开发需要 Xcode 12 或更高版本
- Android 开发需要 Android Studio 或 VS Code

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/nova728/edu_flutter.git
cd edu_flutter_app
```

2. **安装依赖**
```bash
flutter pub get
```

3. **检查环境**
```bash
flutter doctor
```

4. **运行项目**

Web 端:
```bash
 flutter run -d chrome --web-port=55136
```

iOS 模拟器:
```bash
flutter run -d ios
```

Android 模拟器:
```bash
flutter run -d android
```

使用本地 API (可选):
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## 更新日志

### 11-11

#### 项目更新说明

- 前端登录/注册流程新增省份选择，并接入注册接口校验。
- 个人信息页调用 `/student-score/mine` 展示最新成绩，院校页支持省份筛选与院校详情查看。
- 推荐、院校等页面完成导航互通和卡片样式优化，完善按钮交互。
- 后端开放 `/colleges` 查询能力

### 11-13

#### 项目更新说明

- 完善高考页面（info_page.dart）新增省份选择功能，支持新旧高考
- 更改院校页面（college_page.dart）/ 我的页面（profile_page.dart）布局
- 新增收藏院校页面（favorite_colleges_page.dart），实现院校收藏功能
- 优化推荐页面（recommend_page.dart）交互体验

### 11-16

- API改为穿透
- 完善院校查询、筛选、详情、历年录取等接口
- 添加历年录取分数线查看模块：院校➡️全国院校➡️对应大学详情页➡️历年录取

### 交互问题

- [ ] 院校页面（collegeg_page.dart）有一个收藏功能，对应的数据库表现在是否有收藏字段



首先是我们的登录页面，我们先注册一个用户test，这个用户已经注册过了所以校验的时候会失败，用户密码存储是用的多轮随机盐加密存储哈希值实现的，我们修改用户名重新注册；

注册后会自动登录进入应用首页，此时因为用户还没有填写成绩信息，显示内容为空；点击我的进入可以修改账户信息，可以修改用户名、毕业高中及密码；

让我们回到高考信息填写页面，这里分为新高考和旧高考两种类型，旧高考分文理，新高考6选3；可选的考试类型也分为两类，高考和模拟考，

我们这里使用旧高考、理科作为演示。需要填写的信息是高考年份、各科成绩及省排名，快速填写一下，然后再类似的填写几次模拟考分数以便后续可视化的内容展示；

在高考信息填写页面的最下面，有查看成绩分析、编辑个人资料、志愿偏好设置的跳转按钮，点击查看成绩分析进入成绩分析页面，这里会显示我们填写的近期成绩，在这里可以配置 Deepseek 的API Key，把成绩信息提交给 Deepseek 进行成绩分析，返回成绩分析报告；

点击志愿偏好设置进入志愿推荐页面，在这里可以设置智能推荐算法的权重配置，其中固定的是基于历年录取分数线数据的 80% 客观数据分析，剩余的 20% 是由用户可选的目标地区、院校层次、专业方向三个因素组成的客观因素，也就是用户可以调整权重的部分。自动平衡是调整一者，剩下两者根据原先比例均分增减；当然手动调整也是可以的；

在权重配置下方是具体的偏好设置，选择好目标地区、院校层次、专业方向后点击保存并应用即可，可能有点延迟，可以点一下右下角的同步刷新按钮；可以看到生成了 5 所保底院校，1 所稳妥院校，3 所冲刺院校，5 所参考院校；以及一个推荐列表的院校热门地区图

参考院校就是基本不用考虑的hh，如果用户还没有填写高考分数的话用最近一次模拟考的进行评估倒是可以考虑；

在这里生成的推荐列表中可以把心仪的院校添加到收藏目标院校中；这样信息采集的部分完成了，回到首页可以看到更新后的数据，最上面是你的高考分数或者最近一次模拟考分数，上次智能推荐的匹配院校数目，以及收藏的目标院校数目；还有跳转到各个页面的按钮

这个专业信息查询可以模糊匹配专业名称，查看专业的一些信息，受限于数据原因，这里使用的模拟数据

下面是一些可视化的结果，成绩趋势、一分一段表以及各科成绩分析

下面我们看院校信息页，这里可以查看全国院校的信息及自己高中历年录取数据；比如这里我们已北理工为例，点开后可以看到院校信息、历年录取、招生计划三个数据；受限于数据，高中录取数据使用的是模拟数据，这里可以查看高中成功被各院校录取的人数和最低分；

最后还有一个root用户的数据爬取控制，可以手动爬取数据并导入数据库或者设置自动导入


