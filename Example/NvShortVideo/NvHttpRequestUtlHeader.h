//
//  NvHttpRequestUtlHeader.h
//  NvShortVideo
//
//  Created by ms20221114 on 2024/3/18.
//

#ifndef NvHttpRequestUtlHeader_h
#define NvHttpRequestUtlHeader_h

#define TestMaterial

#ifdef TestMaterial

//测试环境
//test

/// 根据分类获取素材列表
/// Get a list of materials by category
NSString* NV_ASSET_REQUEST_URL  =  @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/mall/custom/listAllAssemblyMaterial";

/// 根据素材类型获取素材分类列表
/// Gets a classified list of materials based on their type
NSString* NV_ASSET_CATEGORY_URL  =  @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/appSdkApi/listTypeAndCategory";

/// 获取音乐列表
/// Get music list
NSString* NV_ASSET_MUSICIANS_URL = @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/appSdkApi/listMusic";

/// 获取字体列表
/// Get font list
NSString* NV_ASSET_FONT_URL = @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/listFont";

/// 把素材的id作为参数传入，获取到素材下载的链接
/// Pass in the id of the material as a parameter to get the link to the material download
NSString* NV_ASSET_DOWNLOAD_URL = @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/mall/custom/materialInteraction";

/// 获取预制素材
/// Get the Prefabricated material for the project
NSString* NV_ASSET_PREFABRICATED_URL = @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/beautyAssets/latest";

/// 一键成片
/// AutoCut
NSString* NV_ASSET_AUTOCUT_URL = @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/recommend/listTemplate";

/// 获取模版的标签分类
/// Gets the label classification of the template
NSString* NV_ASSET_TAG_URL = @"https://mall.meishesdk.com/api/shortvideo/test/materialcenter/listTemplateTag";


NSString* NV_ClientId = @"7480f2bf193d417ea7d93d64";
NSString* NV_ClientSecret = @"e4434ff769404f64b33f462331a80957";
NSString* NV_AssemblyId = @"MEISHE_MATERIAL_LIST";

#else

//正式环境
//product

/// 根据分类获取素材列表
/// Get a list of materials by category
NSString* NV_ASSET_REQUEST_URL  =  @"https://mall.meishesdk.com/api/shortvideo/materialcenter/mall/custom/listAllAssemblyMaterial";

/// 根据素材类型获取素材分类列表
/// Gets a classified list of materials based on their type
NSString* NV_ASSET_CATEGORY_URL  =  @"https://mall.meishesdk.com/api/shortvideo/materialcenter/appSdkApi/listTypeAndCategory";

/// 获取音乐列表
/// Get music list
NSString* NV_ASSET_MUSICIANS_URL = @"https://mall.meishesdk.com/api/shortvideo/materialcenter/appSdkApi/listMusic";

/// 获取字体列表
/// Get font list
NSString* NV_ASSET_FONT_URL = @"https://mall.meishesdk.com/api/shortvideo/materialcenter/listFont";

/// 把素材的id作为参数传入，获取到素材下载的链接
/// Pass in the id of the material as a parameter to get the link to the material download
NSString* NV_ASSET_DOWNLOAD_URL = @"https://mall.meishesdk.com/api/shortvideo/materialcenter/mall/custom/materialInteraction";

/// 获取预制素材
/// Get the Prefabricated material for the project
NSString* NV_ASSET_PREFABRICATED_URL = @"https://mall.meishesdk.com/api/shortvideo/materialcenter/beautyAssets/latest";

/// 一键成片
/// AutoCut
NSString* NV_ASSET_AUTOCUT_URL = @"https://mall.meishesdk.com/api/shortvideo/materialcenter/recommend/listTemplate";

/// 获取模版的标签分类
/// Gets the label classification of the template
NSString* NV_ASSET_TAG_URL = @"https://mall.meishesdk.com/api/shortvideo/materialcenter/listTemplateTag";


NSString* NV_ClientId = @"7480f2bf193d417ea7d93d64";
NSString* NV_ClientSecret = @"e4434ff769404f64b33f462331a80957";
NSString* NV_AssemblyId = @"MEISHE_MATERIAL_LIST";

#endif

#endif /* NvHttpRequestUtlHeader_h */
