<template>
  <div class="login-container">
    <div class="login-wrapper">
      <el-form ref="loginForm" :model="loginForm" :rules="loginRules" class="login-form" auto-complete="on" label-position="left">
        <div class="title-container">
          <div class="logo-wrapper">
            <img :src="logoSrc" class="logo" alt="Logo">
          </div>
          <h3 class="title">专卖行政执法音像记录管理系统</h3>
        </div>

        <el-form-item prop="username">
          <el-input
            ref="username"
            v-model="loginForm.username"
            placeholder="用户名"
            name="username"
            type="text"
            tabindex="1"
            auto-complete="on"
          >
            <span slot="prefix" class="svg-container">
              <svg-icon icon-class="user" />
            </span>
          </el-input>
        </el-form-item>

        <el-form-item prop="password">
          <el-input
            :key="passwordType"
            ref="password"
            v-model="loginForm.password"
            :type="passwordType"
            placeholder="密码"
            name="password"
            tabindex="2"
            auto-complete="on"
            @keyup.enter.native="handleLogin"
          >
            <span slot="prefix" class="svg-container">
              <svg-icon icon-class="password" />
            </span>
            <span slot="suffix" class="show-pwd" @click="showPwd">
              <svg-icon :icon-class="passwordType === 'password' ? 'eye' : 'eye-open'" />
            </span>
          </el-input>
        </el-form-item>

        <el-button :loading="loading" type="primary" style="width:360px;margin: 0 auto 30px auto; display: block; background-color: #006838; border-color: #006838;" @click.native.prevent="handleLogin">登录</el-button>

      </el-form>
    </div>

  </div>
</template>

<script>
import {validUsername} from '@/utils/validate'
import logoSrc from '@/icons/logosimple.png'

export default {
  name: 'Login',
  data() {
    const validateUsername = (rule, value, callback) => {
      if (!validUsername(value)) {
        callback(new Error('请输入用户名'))
      } else {
        callback()
      }
    }
    const validatePassword = (rule, value, callback) => {
      callback()
    }
    return {
      logoSrc: logoSrc,
      loginForm: {
        username: '',
        password: ''
      },
      loginRules: {
        username: [{ required: true, trigger: 'blur', validator: validateUsername }],
        password: [{ required: true, trigger: 'blur', validator: validatePassword }]
      },
      loading: false,
      passwordType: 'password',
      redirect: undefined
    }
  },
  watch: {
    $route: {
      handler: function(route) {
        this.redirect = route.query && route.query.redirect
      },
      immediate: true
    }
  },
  methods: {
    showPwd() {
      if (this.passwordType === 'password') {
        this.passwordType = ''
      } else {
        this.passwordType = 'password'
      }
      this.$nextTick(() => {
        this.$refs.password.focus()
      })
    },
    handleLogin() {
      this.$refs.loginForm.validate(valid => {
        if (valid) {
          this.loading = true
          this.$store.dispatch('user/login', this.loginForm).then((re) => {
            this.$router.push({ path: this.redirect || '/' })
            this.loading = false
          }).catch((error) => {
              this.$message({
                showClose: true,
                message: error,
                type: 'error'
              })
            })
            .finally(() => {
              this.loading = false
            })
        } else {
          console.log('error submit!!')
          return false
        }
      })
    }
  }
}
</script>

<style lang="scss">
$bg:#ffffff;
$light_gray:#303133;
$cursor: #303133;

/* reset element-ui css */
.login-container {
  margin: 0;
  width: 100%;
  height: 100%;
  user-select: none;
  
  .el-input {
    display: block;
    height: 47px;
    width: 360px;
    margin: 0 auto;

    input {
      background: #f5f7fa;
      border: 1px solid #dcdfe6;
      border-radius: 4px;
      padding: 12px 35px 12px 35px; // Ensure padding avoids overlap with prefix/suffix icons
      color: $light_gray;
      height: 47px;
      caret-color: $cursor;

      &:focus {
        border-color: #006838;
        background: #ffffff;
      }

      &:-webkit-autofill {
        box-shadow: 0 0 0px 1000px #ffffff inset !important;
        -webkit-text-fill-color: $cursor !important;
      }
    }
  }

  .el-form-item {
    border: none;
    background: transparent;
    border-radius: 0;
    color: #454545;
    margin-bottom: 22px;
    text-align: center;
  }
}
</style>

<style lang="scss" scoped>
$bg: #f0f2f5;
$dark_gray:#889aa4;
$light_gray:#303133;
$tobacco_green: #006838;
$tobacco_light: #4caf50;

.login-container {
    min-height: 100vh;
    width: 100%;
    background-color: #f1f8e9; /* Light green base */
    /* Abstract Green SVG Background */
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1440 320'%3E%3Cpath fill='%23c8e6c9' fill-opacity='1' d='M0,224L48,213.3C96,203,192,181,288,181.3C384,181,480,203,576,224C672,245,768,267,864,261.3C960,256,1056,224,1152,197.3C1248,171,1344,149,1392,138.7L1440,128L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z'%3E%3C/path%3E%3Cpath fill='%23a5d6a7' fill-opacity='0.6' d='M0,96L48,112C96,128,192,160,288,186.7C384,213,480,235,576,213.3C672,192,768,128,864,128C960,128,1056,192,1152,208C1248,224,1344,192,1392,176L1440,160L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z'%3E%3C/path%3E%3Cpath fill='%2381c784' fill-opacity='0.4' d='M0,192L48,197.3C96,203,192,213,288,229.3C384,245,480,267,576,250.7C672,235,768,181,864,170.7C960,160,1056,192,1152,197.3C1248,203,1344,181,1392,170.7L1440,160L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z'%3E%3C/path%3E%3C/svg%3E");
    background-size: cover;
    background-repeat: no-repeat;
    background-position: bottom;
    overflow: hidden;

  .login-wrapper {
    display: flex;
    justify-content: center;
    align-items: center;
    width: 100%;
    height: 100vh;
  }

  .login-form {
    position: relative;
    width: 480px;
    max-width: 100%;
    height: auto;
    padding: 40px;
    margin: 0 auto;
    overflow: hidden;
    background: #ffffff;
    border-radius: 12px;
    box-shadow: 0 8px 32px 0 rgba(0, 104, 56, 0.15); // Green-tinted shadow
    border-top: 4px solid $tobacco_green; // Accent border
  }

  .tips {
    font-size: 14px;
    color: #fff;
    margin-bottom: 10px;

    span {
      &:first-of-type {
        margin-right: 16px;
      }
    }
  }

  .svg-container {
    color: $dark_gray;
    vertical-align: middle;
    width: 30px;
    display: inline-block;
    height: 100%;
    line-height: 47px;
    text-align: center;
  }

  .title-container {
    position: relative;

    .logo-wrapper {
      text-align: center;
      margin-bottom: 20px;

      .logo {
        height: 60px;
        width: auto;
        vertical-align: middle;
      }
    }

    .title {
      font-size: 26px;
      color: $light_gray;
      margin: 0px auto 40px auto;
      text-align: center;
      font-weight: 600;
      font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', '微软雅黑', Arial, sans-serif;
    }
  }

  .show-pwd {
    font-size: 16px;
    color: $dark_gray;
    cursor: pointer;
    user-select: none;
    height: 100%;
    line-height: 47px;
    display: inline-block;
    width: 30px;
    text-align: center;
  }
}
</style>
