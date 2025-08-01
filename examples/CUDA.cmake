# 查找CUDA工具包
find_package(CUDAToolkit REQUIRED)
enable_language(CUDA)

# 设置CUDA架构
# set(CMAKE_CUDA_ARCHITECTURES 75 80 86)
# auto detect architectures
set(CMAKE_CUDA_ARCHITECTURES "native")
# 设置CUDA标准
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

#set(CUDA_KERNELS_DIR "${PROJECT_SOURCE_DIR}/AI/CUDA/kernels")
#[[添加CUDA编译选项
适合使用 --use_fast_math 的场景:
1. 图形和图像处理应用
2. 机器学习训练
3. 物理模拟和游戏

不应使用 --use_fast_math 的场景
1. 科学计算和数值分析
   气候模型和天气预报, 计算流体力学(CFD), 分子动力学模拟, 精确的物理模拟
2. 金融和经济模型: 风险评估和定价模型, 期权定价, 高频交易算法
3. 密码学和安全应用
4. 测试和验证

sin, cos, tan	最大误差约为1-2个ULP	2-10倍
exp, log	最大误差约为1-3个ULP	2-5倍
pow	最大误差可达几个ULP	2-7倍
sqrt	最大误差约为1个ULP	1.5-3倍
除法操作	精度略有降低	1.5-2倍
ULP (Unit in the Last Place) 是衡量浮点精度的单位，表示在给定数值的最低有效位上的一个单位变化。
]]
target_compile_options(concurrent_host_device PRIVATE $<$<COMPILE_LANGUAGE:CUDA>:
    --use_fast_math
    #-lineinfo
>)
# 为所有CUDA文件添加--use_fast_math
add_compile_options($<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>)

# 创建接口库以保存CUDA编译选项
add_library(cuda_fast_math INTERFACE)
target_compile_options(cuda_fast_math INTERFACE $<$<COMPILE_LANGUAGE:CUDA>:--use_fast_math>)
add_executable(app1 src/main1.cu)
target_link_libraries(app1 PRIVATE cuda_fast_math)
