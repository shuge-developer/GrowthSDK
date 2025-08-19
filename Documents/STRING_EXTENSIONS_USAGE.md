# 字符串判空扩展使用示例

## 🎯 扩展功能

在 `String+Crypto.swift` 中添加了字符串判空的扩展方法，提供了更简洁和安全的字符串判空操作。

## 📱 扩展方法

### 1. String 扩展

```swift
internal extension String {
    
    /// 判断字符串是否为空（包括空字符串、只包含空白字符）
    var isNullOrEmpty: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 判断字符串是否有效（非空且非空白）
    var isValid: Bool {
        return !self.isNullOrEmpty
    }
    
}
```

### 2. Optional<String> 扩展

```swift
internal extension Optional where Wrapped == String {
    
    /// 判断可选字符串是否为空（包括 nil、空字符串、只包含空白字符）
    var isNullOrEmpty: Bool {
        guard let string = self else { return true }
        return string.isNullOrEmpty
    }
    
    /// 判断可选字符串是否有效（非空且非空白）
    var isValid: Bool {
        guard let string = self else { return false }
        return string.isValid
    }
    
    /// 安全获取字符串值，如果为空则返回空字符串
    func orEmpty() -> String {
        return self ?? ""
    }
    
    /// 安全获取字符串值，如果为空则返回默认值
    func orDefault(_ defaultValue: String) -> String {
        return self ?? defaultValue
    }
    
}
```

## 🔧 使用示例

### 1. 基本判空操作

```swift
// 字符串判空
let emptyString = ""
let whitespaceString = "   "
let validString = "hello"

print(emptyString.isNullOrEmpty)      // true
print(whitespaceString.isNullOrEmpty) // true
print(validString.isNullOrEmpty)      // false

print(emptyString.isValid)      // false
print(whitespaceString.isValid) // false
print(validString.isValid)      // true
```

### 2. 可选字符串判空

```swift
// 可选字符串判空
let nilString: String? = nil
let emptyOptional: String? = ""
let validOptional: String? = "hello"

print(nilString.isNullOrEmpty)      // true
print(emptyOptional.isNullOrEmpty)  // true
print(validOptional.isNullOrEmpty)  // false

print(nilString.isValid)      // false
print(emptyOptional.isValid)  // false
print(validOptional.isValid)  // true
```

### 3. 安全获取值

```swift
// 安全获取字符串值
let nilString: String? = nil
let emptyString: String? = ""

print(nilString.orEmpty())           // ""
print(nilString.orDefault("默认值"))  // "默认值"
print(emptyString.orEmpty())         // ""
print(emptyString.orDefault("默认值")) // ""
```

## 🛡️ 在 ConfigFetcher 中的应用

### 原始代码（复杂）
```swift
// 原始的安全检查方式
guard let id = bean.id, !id.isEmpty,
      let content = bean.jsonContent, !content.isEmpty else {
    print("[ConfigFetcher] 跳过无效的配置项: id=\(bean.id ?? "nil"), content=\(bean.jsonContent ?? "nil")")
    continue
}
configDict[id] = content
```

### 使用扩展后（简洁）
```swift
// 使用扩展方法的安全检查
guard let id = bean.id, id.isValid,
      let content = bean.jsonContent, content.isValid else {
    print("[ConfigFetcher] 跳过无效的配置项: id=\(bean.id.orEmpty()), content=\(bean.jsonContent.orEmpty())")
    continue
}
configDict[id] = content
```

### 更简洁的写法
```swift
// 如果扩展方法正确工作，可以这样写
guard bean.id.isValid, bean.jsonContent.isValid else {
    print("[ConfigFetcher] 跳过无效的配置项: id=\(bean.id.orEmpty()), content=\(bean.jsonContent.orEmpty())")
    continue
}
configDict[bean.id!] = bean.jsonContent!
```

## 🎉 优势总结

### 1. **代码简洁**
- ✅ 减少重复的判空代码
- ✅ 更易读的语义化方法名
- ✅ 统一的判空逻辑

### 2. **类型安全**
- ✅ 编译时类型检查
- ✅ 避免强制解包错误
- ✅ 安全的默认值处理

### 3. **功能完整**
- ✅ 支持 nil 值检查
- ✅ 支持空字符串检查
- ✅ 支持空白字符检查
- ✅ 提供默认值方法

### 4. **易于维护**
- ✅ 集中管理判空逻辑
- ✅ 易于扩展新功能
- ✅ 统一的错误处理

## 🚀 使用建议

### 1. 基本判空
```swift
// 推荐使用
if string.isValid {
    // 处理有效字符串
}

// 不推荐
if !string.isEmpty && !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
    // 处理有效字符串
}
```

### 2. 可选字符串判空
```swift
// 推荐使用
if optionalString.isValid {
    // 处理有效字符串
}

// 不推荐
if let string = optionalString, !string.isEmpty {
    // 处理有效字符串
}
```

### 3. 安全获取值
```swift
// 推荐使用
let safeString = optionalString.orDefault("默认值")

// 不推荐
let safeString = optionalString ?? "默认值"
```

### 4. 在配置处理中的应用
```swift
// 在 ConfigFetcher 中使用
for bean in response.configBeans {
    guard let id = bean.id, id.isValid,
          let content = bean.jsonContent, content.isValid else {
        print("[ConfigFetcher] 跳过无效的配置项: id=\(bean.id.orEmpty()), content=\(bean.jsonContent.orEmpty())")
        continue
    }
    configDict[id] = content
}
```

这个字符串判空扩展既**简化了代码**，又**提高了安全性**，是一个**实用、简洁、易维护**的解决方案！
