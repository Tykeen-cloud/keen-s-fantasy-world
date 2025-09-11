import numpy as np
import matplotlib.pyplot as plt
from scipy.interpolate import make_interp_spline
plt.rcParams['font.sans-serif'] = ['SimHei']  # 显示中文
plt.rcParams['axes.unicode_minus'] = False
x=[0,0.25,0.5,0.75,1.0,1.25,1.5,1.75,2.0,2.25,2.5,2.75]
y=[0,1.6,4.2,5.2,6.7,9.2,10.2,11.5,13.3,15.2,18,18.4]
x_new = np.linspace(min(x), max(x), 300)
spl = make_interp_spline(x, y, k=3)
y_smooth = spl(x_new)
plt.plot(x_new,y_smooth)
plt.title('磁致旋光角与励磁电流方向关系图线')
plt.xlabel('励磁电流I(A)')
plt.ylabel('磁致旋光角θ(°)')
plt.show()
