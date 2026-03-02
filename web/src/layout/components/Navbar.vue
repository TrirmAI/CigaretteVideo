<template>
  <div class="navbar">
    <hamburger :is-active="sidebar.opened" class="hamburger-container" @toggleClick="toggleSideBar" />

    <div class="system-title">专卖行政执法音像记录管理系统</div>

    <breadcrumb class="breadcrumb-container" />

    <div class="right-menu">
      <div class="right-menu-item hover-effect" @click="toggleTheme" title="切换主题">
         <i :class="theme === 'dark' ? 'el-icon-sunny' : 'el-icon-moon'" style="font-size: 20px;"></i>
      </div>
      <el-dropdown class="avatar-container right-menu-item hover-effect" trigger="click">
        <div class="avatar-wrapper">
          欢迎，{{ name }}
          <i class="el-icon-caret-bottom" />
        </div>
        <el-dropdown-menu slot="dropdown" class="user-dropdown">
          <el-dropdown-item @click.native="changePassword">
            <span style="display:block;">修改密码</span>
          </el-dropdown-item>
          <el-dropdown-item @click.native="logout">
            <span style="display:block;">注销</span>
          </el-dropdown-item>
        </el-dropdown-menu>
      </el-dropdown>
    </div>
    <changePasswordDialog ref="changePasswordDialog"></changePasswordDialog>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import Breadcrumb from '@/components/Breadcrumb'
import Hamburger from '@/components/Hamburger'
import changePasswordDialog from './dialog/changePassword.vue'

export default {
  components: {
    Breadcrumb,
    Hamburger,
    changePasswordDialog
  },
  computed: {
    ...mapGetters([
      'sidebar',
      'name'
    ]),
    theme() {
      return this.$store.state.settings.theme
    }
  },
  methods: {
    toggleSideBar() {
      this.$store.dispatch('app/toggleSideBar')
    },
    toggleTheme() {
      const newTheme = this.theme === 'dark' ? 'light' : 'dark'
      this.$store.dispatch('settings/changeSetting', { key: 'theme', value: newTheme })
      this.$message.success('已切换至 ' + (newTheme === 'dark' ? '深色' : '浅色') + ' 模式')
    },
    async logout() {
      await this.$store.dispatch('user/logout')
      console.log('logout')
      this.$router.push(`/login?redirect=${this.$route.fullPath}`)
    },
    changePassword() {
      this.$refs.changePasswordDialog.openDialog(this.logout)
    }
  }
}
</script>

<style lang="scss" scoped>
.navbar {
  height: 48px;
  overflow: hidden;
  position: relative;
  background: var(--header-bg);
  box-shadow: 0 1px 4px rgba(0,21,41,.08);

  .hamburger-container {
    line-height: 48px;
    height: 100%;
    float: left;
    cursor: pointer;
    transition: background .3s;
    -webkit-tap-highlight-color:transparent;
    fill: var(--header-text);
    color: var(--header-text);

    &:hover {
      background: rgba(255, 255, 255, .1)
    }
  }

  .system-title {
    float: left;
    height: 100%;
    line-height: 48px;
    font-size: 18px;
    font-weight: 600;
    margin-right: 10px;
    margin-left: 10px;
    color: var(--header-text);
    font-family: 'Microsoft YaHei', '微软雅黑', 'PingFang SC', 'Hiragino Sans GB', 'STHeiti', 'SimSun', sans-serif;
  }

  .breadcrumb-container {
    float: left;
    ::v-deep .el-breadcrumb__inner {
      color: var(--text-color-secondary) !important;
      &.is-link {
        color: var(--header-text) !important;
      }
    }
    ::v-deep .no-redirect {
      color: var(--text-color-regular) !important;
    }
  }

  .right-menu {
    float: right;
    height: 100%;
    display: flex;
    align-items: center;

    &:focus {
      outline: none;
    }

    .right-menu-item {
      display: flex;
      align-items: center;
      padding: 0 8px;
      height: 100%;
      font-size: 18px;
      color: var(--header-text);

      &.hover-effect {
        cursor: pointer;
        transition: background .3s;

        &:hover {
          background: rgba(255, 255, 255, .1)
        }
      }
    }

    .avatar-container {
      margin-right: 30px;

      .avatar-wrapper {
        position: relative;
        cursor: pointer;
        color: var(--header-text);
        display: flex;
        align-items: center;

        .user-avatar {
          cursor: pointer;
          width: 40px;
          height: 40px;
          border-radius: 10px;
        }

        .el-icon-caret-bottom {
          cursor: pointer;
          margin-left: 5px;
          font-size: 12px;
          color: var(--header-text);
        }
      }
    }
  }
}
</style>
