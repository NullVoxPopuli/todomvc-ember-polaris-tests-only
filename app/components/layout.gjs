import { fn, uniqueId } from '@ember/helper';
import { on } from '@ember/modifier';
import { isBlank } from '@ember/utils';

import title from 'ember-page-title/helpers/page-title';
import { cell } from 'ember-resources';
import { TrackedMap, TrackedObject } from 'tracked-built-ins';

let isEnter = (event) => event.keyCode === 13;

let all = 'All';
let active = 'Active';
let completed = 'Completed';

export let activeList = cell(all);
export let canToggleAll = cell(true);
export let isEditing = cell(false);

class Repo {
	data = null;

	load = () => {
		let list = JSON.parse(localStorage.getItem('todos') || '[]');

		this.data = list.reduce((data, todo) => {
			data.set(todo.id, new TrackedObject(todo));

			return data;
		}, new TrackedMap());
	};
  save = () => localStorage.setItem('todos', JSON.stringify(this.all));

	get all() {
		return [...this.data.values()];
	}

	get completed() {
		return this.all.filter((todo) => todo.completed);
	}

	get active() {
		return this.all.filter((todo) => !todo.completed);
	}

	get areAllCompleted() {
		return this.completed.length === this.all.length;
	}

	add = info => {
		let newId = uniqueId();

		this.data.set(newId, new TrackedObject({ ...info, id: newId }));
		this.save();
	};

	delete = todo => {
		this.data.delete(todo.id);
		this.save();
	};
	clearCompleted = () => this.completed.forEach(this.delete);
  markAll = (todos, value) => {
    todos.forEach(todo => todo.completed = value);
    this.save();
  }
}

export let repo = new Repo();

let isAll = () => activeList.current === all;
let isActive = () => activeList.current === active;
let isCompleted = () => activeList.current === completed;
let showAll = () => (activeList.current = all);
let showActive = () => (activeList.current = active);
let showCompleted = () => (activeList.current = completed);

let getTitle = () => (isAll() ? all : isActive() ? active : completed);
let getTodos = () =>
	isAll() ? repo.all : isActive() ? repo.active : repo.completed;

let TodoApp = <template>
	{{repo.load}}

	<section class="todoapp">
		<header class="header">
			<h1>todos</h1>

			<input
				class="new-todo"
				{{on "keydown" createTodo}}
				placeholder="What needs to be done?"
				autofocus
			/>
		</header>

		{{title (getTitle)}}
		<TodoList @todos={{(getTodos)}} />

		{{#if repo.all.length}}
			<Footer />
		{{/if}}
	</section>
</template>;

export default TodoApp;

function createTodo(event) {
	let title = event.target.value.trim();

	if (isEnter(event) && !isBlank(title)) {
		repo.add({ title, completed: false });
		event.target.value = '';
	}
}

let toggleAll = (todos) => repo.markAll(todos, !repo.areAllCompleted);

let TodoList = <template>
	<section class="main">
		{{#if @todos.length}}
			{{#if canToggleAll.current}}
				<input
					id="toggle-all"
					class="toggle-all"
					type="checkbox"
					checked={{repo.areAllCompleted}}
					{{on "change" (fn toggleAll @todos)}}
				/>
				<label for="toggle-all">Mark all as complete</label>
			{{/if}}
			<ul class="todo-list">
				{{#each @todos as |todo|}}
					<TodoItem @todo={{todo}} />
				{{/each}}
			</ul>
		{{/if}}
	</section>
</template>;

let TodoItem = <template>
	<li class="{{if @todo.completed 'completed'}} {{if isEditing.current 'editing'}}">
		<div class="view">
			<input
				class="toggle"
				type="checkbox"
				checked={{@todo.completed}}
				{{on "change" (fn toggleCompleted @todo)}}
			/>
			<label {{on "dblclick" startEditing}}>{{@todo.title}}</label>
			<button class="destroy" {{on "click" (fn repo.delete @todo)}}></button>
		</div>
		<input
			class="edit"
			value={{@todo.title}}
			{{on "blur" (fn doneEditing @todo)}}
			{{on "keydown" itemKeydown}}
			autofocus
		/>
	</li>
</template>;

let toggleCompleted = (todo, event) => repo.markAll([todo], event.target.checked);

function startEditing(event) {
	canToggleAll.current = false;
	isEditing.current = true;

	event.target.closest('li').querySelector('input.edit').focus();
}

function doneEditing(todo, event) {
	if (!isEditing.current) {
		return;
	}

	let title = event.target.value.trim();

	if (isBlank(title)) {
		repo.delete(todo);
	} else {
		todo.title = title;
		isEditing.current = false;
		canToggleAll.current = true;
	}
}

function itemKeydown(event) {
	if (isEnter(event)) {
		event.target.blur();
	} else if (event.keyCode === 27) {
		isEditing.current = false;
	}
}

let itemLabel = (count) => (count === 0 || count > 1) ? 'items' : 'item';

let Footer = <template>
	<footer class="footer">
		<span class="todo-count">
			<strong>{{repo.active.length}}</strong>
			{{itemLabel repo.active.length}}
			left
		</span>

		<ul class="filters">
			<li>
				<a href="#" class={{if (isAll) "selected"}} {{on "click" showAll}}>{{all}}</a>
			</li>
			<li>
				<a href="#" class={{if (isActive) "selected"}} {{on "click" showActive}}>{{active}}</a>
			</li>
			<li>
				<a href="#" class={{if (isCompleted) "selected"}} {{on "click" showCompleted}}>{{completed}}</a>
			</li>
		</ul>

		{{#if repo.completed.length}}
			<button class="clear-completed" {{on "click" repo.clearCompleted}}>
				Clear completed
			</button>
		{{/if}}
	</footer>
</template>;
