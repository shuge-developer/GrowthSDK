//
//  H5ConfigModel.swift
//  GrowthKit
//
//  Created by arvin on 2025/5/29.
//

import Foundation

// MARK: - Enums
internal enum InitStatus: Int16, Codable {
    /// 全关
    case allOff = 0
    /// 买量开，自然关
    case paidOn = 1
    /// 全开
    case allOn = 2
    /// 买量关，自然开
    case organicOn = 3
}

// MARK: - H5ConfigModel
/// H5配置接口返回的数据模型
internal struct H5ConfigModel: Codable, ParseValueable, JSONPostMapping {
    
    // MARK: - Properties
    /// 首次启动获取配置
    var `init`: H5InitConfig?
    
    /// 下发的 H5 链接配置
    var cfg: [String: H5CfgConfig?]?
    
    /// 下发的 JS 代码配置
    var jsM: H5JSConfig?
    var js: String?
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case `init`
        case cfg
        case js
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        `init` = try container.decodeIfPresent(H5InitConfig.self, forKey: .`init`)
        cfg = try container.decodeIfPresent([String: H5CfgConfig?].self, forKey: .cfg)
        js = try container.decodeIfPresent(String.self, forKey: .js)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(`init`, forKey: .`init`)
        try container.encodeIfPresent(cfg, forKey: .cfg)
        try container.encodeIfPresent(js, forKey: .js)
    }
    
    // MARK: - JSONPostMapping
    mutating func didFinishMapping() {
        // 处理嵌套的 H5InitConfig
        if var initConfig = `init` {
            initConfig.didFinishMapping()
            `init` = initConfig
        }
        
        // 解析扩展配置
        parseExtraConfig()
        
        // 解析JS代码配置
        parseJSCodeConfig()
        
        // 解析所有任务类型
        parseAllTaskTypes()
    }
    
    // MARK: - Private Methods
    /// 解析扩展配置
    private mutating func parseExtraConfig() {
        guard let extraString = `init`?.extra else { return }
        if let extraConfig = H5ExtraConfig.deserialize(from: extraString) {
            `init`?.extraM = extraConfig
        }
    }
    
    /// 解析JS代码配置
    private mutating func parseJSCodeConfig() {
        guard let jsCodeString = js else { return }
        if let jsConfig = H5JSConfig.deserialize(from: jsCodeString) {
            jsM = jsConfig
        }
    }
    
    /// 解析所有任务类型
    private mutating func parseAllTaskTypes() {
        cfg = cfg?.compactMapValues { cfgConfig in
            guard var config = cfgConfig else { return nil }
            config.data.indices.forEach {
                config.data[$0].updateTaskType(with: self)
            }
            return config
        }
    }
    
    // MARK: - Computed Properties
    var isEmpty: Bool {
        `init` == nil && cfg == nil && js == nil
    }
}

// MARK: - H5InitConfig
/// init配置数据
internal struct H5InitConfig: Codable, ParseValueable, JSONPostMapping {
    
    // MARK: - Time Configuration Properties
    /// 点击广告存活时间(秒) Click Ad Time
    var cATime: String?
    
    /// 点击功能区存活时间(秒) Click Function Time
    var cFTime: String?
    
    /// 刷新间隔时间，即上次任务完成后，间隔xx秒再获取配置
    var refreshGapTime: String?
    
    /// 开始滑动时间(秒) Start Slide Time
    var sSTime: String?
    
    /// 不点击存活时间(秒) Sleep Time
    /// 即链接展示时间（`H5LinkData.flag`等于 0，这里才生效）
    var sTime: String?
    
    /// 层级加载间隔(秒)（下发多条链接，各链接加载间隔时间）
    var levelGapTime: String?
    
    /// 开始点击时间(秒)
    var sClick: String?
    
    // MARK: - Function Configuration Properties
    /// 点击功能的概率（`H5LinkData.flag`等于 0，这里才生效）
    var function: Double = 0
    
    /// 每日最大刷新次数
    var limit: Int16 = 0
    
    /// 最大层级数（最多有xx条链接同时加载显示）
    var levelMax: Int16 = 0
    
    /// 滑动概率
    var slideRate: Double = 0
    
    /// 状态开关 0是全关,1是买量开，自然关，2是全开 3是买量关，自然开
    var status: InitStatus = .allOff
    
    // MARK: - JS Configuration Properties
    /// 顶部JS代码
    var topJs: String?
    
    // MARK: - Extra Configuration Properties
    /// 扩展配置（JSON字符串）
    var extra: String?
    
    /// 扩展配置，从 extra 解析而来
    var extraM: H5ExtraConfig?
    
    // MARK: - Parsed Properties
    /// 解析后的刷新间隔时间
    var _refreshGapTime: Int16 = 0
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case cATime
        case cFTime
        case refreshGapTime
        case sSTime
        case sTime
        case levelGapTime
        case sClick
        case function
        case limit
        case levelMax
        case slideRate
        case status
        case topJs
        case extra
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 解析时间配置
        cATime = try container.decodeIfPresent(String.self, forKey: .cATime)
        cFTime = try container.decodeIfPresent(String.self, forKey: .cFTime)
        refreshGapTime = try container.decodeIfPresent(String.self, forKey: .refreshGapTime)
        sSTime = try container.decodeIfPresent(String.self, forKey: .sSTime)
        sTime = try container.decodeIfPresent(String.self, forKey: .sTime)
        levelGapTime = try container.decodeIfPresent(String.self, forKey: .levelGapTime)
        sClick = try container.decodeIfPresent(String.self, forKey: .sClick)
        
        // 解析功能配置
        function = try container.decodeIfPresent(Double.self, forKey: .function) ?? 0
        limit = try container.decodeIfPresent(Int16.self, forKey: .limit) ?? 0
        levelMax = try container.decodeIfPresent(Int16.self, forKey: .levelMax) ?? 0
        slideRate = try container.decodeIfPresent(Double.self, forKey: .slideRate) ?? 0
        status = try container.decodeIfPresent(InitStatus.self, forKey: .status) ?? .allOff
        
        // 解析其他配置
        topJs = try container.decodeIfPresent(String.self, forKey: .topJs)
        extra = try container.decodeIfPresent(String.self, forKey: .extra)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 编码时间配置
        try container.encodeIfPresent(cATime, forKey: .cATime)
        try container.encodeIfPresent(cFTime, forKey: .cFTime)
        try container.encodeIfPresent(refreshGapTime, forKey: .refreshGapTime)
        try container.encodeIfPresent(sSTime, forKey: .sSTime)
        try container.encodeIfPresent(sTime, forKey: .sTime)
        try container.encodeIfPresent(levelGapTime, forKey: .levelGapTime)
        try container.encodeIfPresent(sClick, forKey: .sClick)
        
        // 编码功能配置
        try container.encode(function, forKey: .function)
        try container.encode(limit, forKey: .limit)
        try container.encode(levelMax, forKey: .levelMax)
        try container.encode(slideRate, forKey: .slideRate)
        try container.encode(status, forKey: .status)
        
        // 编码其他配置
        try container.encodeIfPresent(topJs, forKey: .topJs)
        try container.encodeIfPresent(extra, forKey: .extra)
    }
    
    // MARK: - JSONPostMapping
    mutating func didFinishMapping() {
        _refreshGapTime = parseRandomInt16(from: refreshGapTime)
    }
}

// MARK: - H5ExtraConfig
/// extra字段解析后的配置（从JSON字符串解析）
internal struct H5ExtraConfig: Codable, ParseValueable, JSONPostMapping {
    
    // MARK: - Core Configuration Properties
    /// 下一条点击的广告展示间隔
    var nextAdGap: String?
    
    /// 使用 JS 注入点击广告的比例
    var jsClickRt: Double = 0.0
    
    /// 点击比例（生成随机数，小于此比例则允许点击功能）
    var clickRt: Double = 0.0
    
    // MARK: - JS Configuration Properties
    /// 初始化底部JS代码
    var initBottomJs: String?
    
    /// 是否到底部的JS代码
    var isBottomJs: String?
    
    /// 获取功能元素位置的JS代码
    var rectJs: String?
    
    // MARK: - Time Configuration Properties
    /// 开始滑动的时间范围（毫秒）
    var startM: String?
    
    /// （滑动）停止时间
    var stopTime: String?
    
    /// 快速点击时间
    var quickCT: String?
    
    /// 长（慢 ）点击时间（最大停留时间）
    var longCT: String?
    
    // MARK: - Rate Configuration Properties
    /// 左边（手）比率
    var leftRate: Double?
    
    /// 左边（手）上移（滑）动比率
    var leftUpMoveRate: Double?
    
    /// 右边（手）上移（滑）动比率
    var upMoveRate: Double?
    
    /// 快速点击时间比率
    var quickCtR: Double?
    
    /// 快速滑动比率
    var quickMove: Double?
    
    // MARK: - Movement Configuration Properties
    /// 滑动的时间分布，最小 400，最大 500
    var moveTimeCenter: Int16?
    
    /// 单次滑动时间标准差，最小 30，最大 130
    var moveTimeSigma: Int16?
    
    // MARK: - Parsed Properties
    var _quickCT: Int16 = 0
    var _stopTime: Int16 = 0
    var _longCT: Int16 = 0
    var _startM: Int16 = 0
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case nextAdGap
        case jsClickRt
        case clickRt
        case initBottomJs
        case isBottomJs
        case rectJs
        case startM
        case stopTime
        case quickCT
        case longCT
        case leftRate
        case leftUpMoveRate
        case upMoveRate
        case quickCtR
        case quickMove
        case moveTimeCenter
        case moveTimeSigma
    }
    
    // MARK: - JSONPostMapping
    mutating func didFinishMapping() {
        _quickCT = parseRandomInt16(from: quickCT)
        _stopTime = parseRandomInt16(from: stopTime)
        _longCT = parseRandomInt16(from: longCT)
        _startM = parseRandomInt16(from: startM)
    }
}

// MARK: - H5CfgConfig
/// 服务商配置
internal struct H5CfgConfig: Codable {
    
    /// 服务商对应的链接信息
    var data: [H5LinkData] = []
    
    /// 服务商维度的js代码
    var js: String?
}

// MARK: - H5LinkData
/// 链接数据
internal struct H5LinkData: Codable, TaskTypeable, ParseValueable, JSONPostMapping {
    
    // MARK: - Core Properties
    /// 插屏名称
    /// 通过名称检测匹配的广告，命中则为插屏
    var inter: String?
    
    /// 插屏广告点击率
    var interRate: Double?
    
    /// 是否点击：0 不点击，1 点击
    var flag: Int16?
    
    /// 链接地址
    var link: String?
    
    // MARK: - Advertisement Properties
    /// 兜底广告区域
    /// 当 `flag` 等于 1，`id` && `type`为空时，则点击此兜底广告区域
    var zone: String?
    
    /// 广告ID
    /// 当 `flag` 等于 1，有值则点击对应 `id`
    /// 当 `flag` 等于 1，无值点击类型 `type`
    var id: String?
    
    /// 广告类型
    /// 当 `flag` 等于 1，`id`不为空时，则匹配检测到的广告类型以及 id 进行点击
    /// 当 `flag` 等于 1，`id`为空时，检测到多个匹配的广告类型，随机点击一个
    var type: String?
    
    // MARK: - Display Properties
    /// 屏幕类型：0 首屏可见广告，1 首屏不可见广告
    /// 当首屏可见广告时，先通过 `init`配置中的 `slideRate`来计算 `TaskType`，再结合功能或广告点击概率来计算 `TaskType`
    /// 当首屏不可见广告时，则必须先滑动，再结合 `init`配置中的功能或广告点击概率来计算 `TaskType`
    var screenType: Int16?
    
    // MARK: - Parsed Properties
    /// 开始滑动时间(秒)
    var _startSlideTime: Float = 0
    
    /// 点击功能区存活时间(秒)
    var _clickFuncTime: Int16 = 0
    
    /// 层级加载间隔(秒)（下发多条链接，各链接加载间隔时间）
    var _levelGapTime: Int16 = 0
    
    /// 点击广告存活时间(秒)
    var _clickAdTime: Int16 = 0
    
    /// 开始点击时间(秒)
    var _startClick: Int16 = 0
    
    /// 不点击存活时间(秒)
    var _sleepTime: Int16 = 0
    
    /// 该链接的任务类型（计算得出）
    var _taskType: TaskType = .show
    
    /// 展示下一条点击的广告的间隔（秒）
    var _nextAdGap: Int16 = 180
    
    // MARK: - Codable
    enum CodingKeys: String, CodingKey {
        case inter
        case interRate
        case flag
        case zone
        case link
        case screenType
        case id
        case type
    }
    
    // MARK: - JSONPostMapping
    mutating func didFinishMapping() {
        // H5LinkData 的后处理逻辑
    }
    
    // MARK: - TaskTypeable
    func calculateTaskType(with initConfig: H5InitConfig? = nil, cacheCfg: InitConfig? = nil) -> TaskType {
        return TaskTypeCalculator.calculate(for: self, with: initConfig, cacheCfg: cacheCfg)
    }
    
    // MARK: - Public Methods
    /// 更新TaskType和时间配置
    /// - Parameter configModel: H5配置模型
    mutating func updateTaskType(with configModel: H5ConfigModel) {
        if let initConfig = configModel.`init` {
            // 使用新的配置
            let nextGap = initConfig.extraM?.nextAdGap
            _nextAdGap = parseRandomInt16(from: nextGap)
            _startSlideTime = parseRandomFloat(from: initConfig.sSTime)
            _levelGapTime = parseRandomInt16(from: initConfig.levelGapTime)
            _clickFuncTime = parseRandomInt16(from: initConfig.cFTime)
            _clickAdTime = parseRandomInt16(from: initConfig.cATime)
            _startClick = parseRandomInt16(from: initConfig.sClick)
            _sleepTime = parseRandomInt16(from: initConfig.sTime)
            _taskType = calculateTaskType(with: initConfig)
        } else {
            // 使用缓存的配置
            let cacheCfg = InitConfig.fetchInitConfig()
            _nextAdGap = parseRandomInt16(from: cacheCfg?.nextAdGap)
            _levelGapTime = parseRandomInt16(from: cacheCfg?.levelGapTime)
            _startSlideTime = parseRandomFloat(from: cacheCfg?.sSTime)
            _clickFuncTime = parseRandomInt16(from: cacheCfg?.cFTime)
            _clickAdTime = parseRandomInt16(from: cacheCfg?.cATime)
            _startClick = parseRandomInt16(from: cacheCfg?.sClick)
            _sleepTime = parseRandomInt16(from: cacheCfg?.sTime)
            _taskType = calculateTaskType(cacheCfg: cacheCfg)
        }
    }
}

// MARK: - H5JSConfig
/// js 代码配置
internal struct H5JSConfig: Codable {
    
    /// 获取功能位置的 js 代码
    var rectJs: String?
    
    /// H5 点击交互的 js 代码
    var clickJs: String?
    
    /// 到达页面底部的 js 代码
    var bottomJs: String?
    
    /// 检查 iframe 位置的 js 代码
    var iframeJs: String?
    
    /// 到达页面顶部的 js 代码
    var topJs: String?
}
