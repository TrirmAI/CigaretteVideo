<template>
  <div class="sidebar-logo-container" :class="{'collapse':collapse}">
    <transition name="sidebarLogoFade">
      <router-link v-if="collapse" key="collapse" class="sidebar-logo-link" to="/">
        <img v-if="logoCollapse" :src="logoCollapse" class="sidebar-logo-icon">
        <h1 v-else class="sidebar-title">{{ title }} </h1>
      </router-link>
      <router-link v-else key="expand" class="sidebar-logo-link" to="/">
        <img v-if="logo" :src="logo" class="sidebar-logo-full">
        <h1 v-else class="sidebar-title">{{ title }} </h1>
      </router-link>
    </transition>
  </div>
</template>

<script>
import logoSrc from '@/icons/logosimple.png'
import logoCollapseSrc from '@/icons/logosupersimple.png'

export default {
  name: 'SidebarLogo',
  props: {
    collapse: {
      type: Boolean,
      required: true
    }
  },
  data() {
    return {
      title: 'WVP PRO',
      logo: logoSrc,
      logoCollapse: logoCollapseSrc
    }
  }
}
</script>

<style lang="scss" scoped>
.sidebarLogoFade-enter-active {
  transition: opacity 1.5s;
}

.sidebarLogoFade-enter,
.sidebarLogoFade-leave-to {
  opacity: 0;
}

.sidebar-logo-container {
  position: relative;
  width: 100%;
  height: 48px;
  line-height: 48px;
  background: var(--menu-bg);
  text-align: center;
  overflow: hidden;

  & .sidebar-logo-link {
    height: 100%;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: center;

    & .sidebar-logo-icon {
      width: 100%;
      height: 100%;
      vertical-align: middle;
      margin-right: 0px;
      object-fit: contain;
      padding: 2px 5px;
    }

    & .sidebar-logo-full {
      height: 100%;
      width: 100%;
      max-width: 100%;
      vertical-align: middle;
      object-fit: contain;
      padding: 2px 10px;
    }

    & .sidebar-title {
      display: inline-block;
      margin: 0;
      color: #fff;
      font-weight: 600;
      line-height: 50px;
      font-size: 14px;
      font-family: Avenir, Helvetica Neue, Arial, Helvetica, sans-serif;
      vertical-align: middle;
    }
  }

  &.collapse {
    .sidebar-logo-icon {
      margin-right: 0px;
    }
  }
}
</style>
